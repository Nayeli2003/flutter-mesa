import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'package:http/http.dart' as http;

// Para contentType en multipart (video/image)
import 'package:http_parser/http_parser.dart';

class CreateTicketView extends StatefulWidget {
  const CreateTicketView({super.key});

  @override
  State<CreateTicketView> createState() => _CreateTicketViewState();
}

class _CreateTicketViewState extends State<CreateTicketView> {
  final _formKey = GlobalKey<FormState>();

  final asuntoController = TextEditingController();
  final descripcionController = TextEditingController();

  String? sucursal;
  String? categoria;

  // Evidencias (imágenes o videos)
  final List<PlatformFile> evidencias = [];

  @override
  void dispose() {
    asuntoController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidencias() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'mkv', 'avi'],
      withData: kIsWeb, // en WEB necesitamos bytes para previews (imagenes)
      withReadStream: kIsWeb, // en WEB necesitamos stream para videos grandes
    );

    if (result == null) return;

    setState(() {
      for (final f in result.files) {
        final exists = evidencias.any((e) => e.name == f.name && e.size == f.size);
        if (!exists) evidencias.add(f);
      }
    });
  }

  void _removeEvidencia(PlatformFile file) {
    setState(() => evidencias.remove(file));
  }

  bool _isImage(PlatformFile f) {
    final ext = (f.extension ?? '').toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(ext);
  }

  bool _isVideo(PlatformFile f) {
    final ext = (f.extension ?? '').toLowerCase();
    return ['mp4', 'mov', 'mkv', 'avi'].contains(ext);
  }

  MediaType? _contentTypeFor(PlatformFile f) {
    final ext = (f.extension ?? '').toLowerCase();

    if (_isImage(f)) {
      // jpg -> jpeg
      final sub = ext == 'jpg' ? 'jpeg' : ext;
      return MediaType('image', sub);
    }

    if (_isVideo(f)) {
      // Algunos servidores esperan tipos específicos:
      // avi suele ser video/x-msvideo
      if (ext == 'avi') return MediaType('video', 'x-msvideo');
      // mp4, mov, mkv
      return MediaType('video', ext);
    }

    return null;
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // 1. Mostrar indicador de carga (Loading)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      ),
    );

    try {
      // 2. Configurar la petición (Ajusta la URL a tu API real)
      final url = Uri.parse('https://tu-servidor.com/api/tickets');
      var request = http.MultipartRequest('POST', url);

      // 3. Agregar campos de texto
      request.fields['asunto'] = asuntoController.text.trim();
      request.fields['descripcion'] = descripcionController.text.trim();
      request.fields['sucursal'] = sucursal ?? '';
      request.fields['categoria'] = categoria ?? '';

      // 4. Agregar archivos (Evidencias)
      for (var f in evidencias) {
        final ct = _contentTypeFor(f);

        if (kIsWeb) {
          final isVid = _isVideo(f);

          if (isVid) {
            // WEB VIDEO: subir por stream (mejor para archivos grandes)
            if (f.readStream != null) {
              request.files.add(
                http.MultipartFile(
                  'files', // Nombre del campo que espera tu backend
                  f.readStream!,
                  f.size,
                  filename: f.name,
                  contentType: ct,
                ),
              );
            } else if (f.bytes != null) {
              // Fallback: si por alguna razón sí hay bytes
              request.files.add(
                http.MultipartFile.fromBytes(
                  'files',
                  f.bytes!,
                  filename: f.name,
                  contentType: ct,
                ),
              );
            }
          } else {
            // WEB IMAGEN: bytes para preview + subida
            if (f.bytes != null) {
              request.files.add(
                http.MultipartFile.fromBytes(
                  'files',
                  f.bytes!,
                  filename: f.name,
                  contentType: ct,
                ),
              );
            }
          }
        } else {
          // MÓVIL: usamos path (imagen o video)
          if (f.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'files',
                f.path!,
                filename: f.name,
                contentType: ct,
              ),
            );
          }
        }
      }

      // 5. Enviar y esperar respuesta
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Quitar el Loading
      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ÉXITO
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket enviado con éxito')),
        );
        Navigator.pop(context); // Regresar a la lista
      } else {
        // ERROR DE SERVIDOR
        throw Exception('Error en el servidor: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      // Error de red o código
      if (mounted) Navigator.pop(context); // Quitar loading si hay error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Crear ticket',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      drawer: const AppDrawer(role: UserRole.sucursal, title: 'Sucursal'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              //  Formulario con validación
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: asuntoController,
                      decoration: InputDecoration(
                        labelText: 'Asunto',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El asunto es obligatorio';
                        }
                        if (value.trim().length < 4) {
                          return 'Escribe al menos 4 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: descripcionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La descripción es obligatoria';
                        }
                        if (value.trim().length < 10) {
                          return 'Describe un poco más (mín. 10 caracteres)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: sucursal,
                      items: const [
                        DropdownMenuItem(value: 'Centro', child: Text('Sucursal Centro')),
                        DropdownMenuItem(value: 'Norte', child: Text('Sucursal Norte')),
                        DropdownMenuItem(value: 'Sur', child: Text('Sucursal Sur')),
                      ],
                      onChanged: (value) => setState(() => sucursal = value),
                      decoration: InputDecoration(
                        labelText: 'Sucursal',
                        prefixIcon: const Icon(Icons.store),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Selecciona una sucursal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: categoria,
                      items: const [
                        DropdownMenuItem(value: 'Internet', child: Text('Internet / Red')),
                        DropdownMenuItem(value: 'Equipo', child: Text('Equipo de cómputo')),
                        DropdownMenuItem(value: 'Impresora', child: Text('Impresora')),
                        DropdownMenuItem(value: 'Sistema', child: Text('Sistema / ERP')),
                        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                      ],
                      onChanged: (value) => setState(() => categoria = value),
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Selecciona una categoría';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Evidencias
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Evidencia (imagen / video)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickEvidencias,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Adjuntar'),
                        ),
                      ],
                    ),

                    if (evidencias.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA5D6A7).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Puedes adjuntar fotos o videos como evidencia del problema.',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          const SizedBox(height: 6),
                          ...evidencias.map((f) {
                            final isImg = _isImage(f);
                            final isVid = _isVideo(f);

                            return Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  if (isImg)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: kIsWeb
                                          ? (f.bytes != null
                                              ? Image.memory(
                                                  f.bytes as Uint8List,
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.cover,
                                                )
                                              : _emptyPreview())
                                          : (f.path != null
                                              ? Image.file(
                                                  File(f.path!),
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.cover,
                                                )
                                              : _emptyPreview()),
                                    )
                                  else
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isVid
                                            ? const Color(0xFFF59E0B).withOpacity(0.15)
                                            : const Color(0xFF4CAF50).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isVid ? Icons.videocam : Icons.insert_drive_file,
                                        color: isVid ? const Color(0xFFF59E0B) : const Color(0xFF4CAF50),
                                      ),
                                    ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(f.size / 1024).toStringAsFixed(1)} KB'
                                          '${f.extension != null ? ' • .${f.extension}' : ''}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    tooltip: 'Quitar',
                                    onPressed: () => _removeEvidencia(f),
                                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),

                    const SizedBox(height: 18),

                    // Nota prioridad automática
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA5D6A7).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'La prioridad (🟥🟧🟩) la asigna el sistema automáticamente según la categoría y reglas de atención.',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submit,
                        icon: const Icon(Icons.send),
                        label: const Text(
                          'Enviar ticket',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyPreview() {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: const Icon(Icons.image),
    );
  }
}
