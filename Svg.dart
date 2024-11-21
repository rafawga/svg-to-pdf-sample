// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Importações necessárias
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

// Função principal
Future<String> gerarCertificado(
  String svgUrl,
  String cor,
  String aluno,
  bool isCurso,
  String teacher,
  String date,
  String duration,
  String curso,
  String code,
  bool hasLogo, // Variável para verificar se a logo deve ser incluída
  String? logoUrl, // URL da logo
  String mainText, // Texto principal com templates
  String authenticationCode, // Código de autenticação
  bool hasProfissional, // Novo booleano
  bool hasDate,
  bool hasDuration,
) async {
  final pdf = pw.Document();

  if (svgUrl.isEmpty) {
    return "A URL do SVG está vazia ou é nula. Não é possível gerar o PDF.";
  }

  try {
    // Carrega o conteúdo do SVG
    final response = await http.get(Uri.parse(svgUrl));
    if (response.statusCode != 200) {
      return "Falha ao carregar o SVG da URL. Código de status: ${response.statusCode}.";
    }

    String svgContent = response.body;

    // Substitui códigos de cor
    final colorPatterns = ['#CCCCCC', '#cccccc', 'CCCCCC', 'cccccc'];
    for (final pattern in colorPatterns) {
      svgContent = svgContent.replaceAll(pattern, cor);
    }

    // Determina 'type'
    String type = isCurso ? 'Curso' : 'Treinamento';

    // Mapa de variáveis
    Map<String, String> variables = {
      'aluno': aluno.trim(),
      'c-type': type.trim(),
      'teacher': teacher.trim(),
      'date': date.trim(),
      'duration': duration.trim(),
      'c-name': curso.trim(),
      'code': code.trim(),
    };

    // Mapa de condições
    Map<String, bool> conditions = {
      'hasProfissional': hasProfissional,
      'hasDate': hasDate,
      'hasDuration': hasDuration,
    };

    // Função para processar o template
    String processTemplate(String template, Map<String, String> variables,
        Map<String, bool> conditions) {
      // Processa as seções condicionais
      RegExp regExp =
          RegExp(r'\{\?(\w+)\}(.*?)\{\/\1\}', multiLine: true, dotAll: true);
      while (regExp.hasMatch(template)) {
        template = template.replaceAllMapped(regExp, (match) {
          String condition = match.group(1)!;
          String content = match.group(2)!;
          bool include = conditions[condition] ?? false;
          return include ? content : '';
        });
      }

      // Substitui os placeholders pelas variáveis correspondentes
      variables.forEach((key, value) {
        template = template.replaceAll('{$key}', value);
      });

      // Remove espaços extras e retorna o texto final
      return template.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    // Processa o mainText usando a função processTemplate
    mainText = processTemplate(mainText, variables, conditions);

    // Processa o authenticationCode (caso tenha placeholders)
    authenticationCode =
        processTemplate(authenticationCode, variables, conditions);

    // Parse do SVG
    final svgXml = xml.XmlDocument.parse(svgContent);

    // Lista para armazenar os IDs dos placeholders a serem removidos
    List<String> placeholdersToRemove = [];

    // Função auxiliar para extrair informações do placeholder
    Map<String, dynamic>? extractPlaceholderInfo(String placeholderId) {
      final elements = svgXml.findAllElements('g').where(
            (element) => element.getAttribute('id') == placeholderId,
          );
      if (elements.isNotEmpty) {
        final placeholderElement = elements.first;
        placeholdersToRemove.add(placeholderId); // Marcar para remoção

        final rectElement = placeholderElement.findElements('rect').first;
        double width = double.parse(rectElement.getAttribute('width') ?? '0');
        double height = double.parse(rectElement.getAttribute('height') ?? '0');
        final transform = rectElement.getAttribute('transform') ?? '';
        final translateMatch = RegExp(r'translate\(([\d\.]+)[,\s]+([\d\.]+)\)')
            .firstMatch(transform);

        double posX = 0, posY = 0;
        if (translateMatch != null) {
          posX = double.parse(translateMatch.group(1) ?? '0');
          posY = double.parse(translateMatch.group(2) ?? '0');
        }

        return {
          'posX': posX,
          'posY': posY,
          'width': width,
          'height': height,
        };
      } else {
        return null;
      }
    }

    // Extrair informações dos placeholders e marcar para remoção
    var alunoInfo = extractPlaceholderInfo('aluno_placeholder');
    var mainInfo = extractPlaceholderInfo('main_placeholder');
    var codeInfo = extractPlaceholderInfo('code_placeholder');
    var imageInfo = extractPlaceholderInfo('image_placeholder');

    // Remover os placeholders do SVG
    placeholdersToRemove.forEach((placeholderId) {
      final elements = svgXml.findAllElements('g').where(
            (element) => element.getAttribute('id') == placeholderId,
          );
      if (elements.isNotEmpty) {
        elements.first.parent?.children.remove(elements.first);
      }
    });

    // Converte o SVG modificado de volta para string
    svgContent = svgXml.toXmlString();

    // Obtém as dimensões do SVG
    final svgElement = svgXml.findAllElements('svg').first;
    double width =
        double.tryParse(svgElement.getAttribute('width') ?? '0') ?? 0;
    double height =
        double.tryParse(svgElement.getAttribute('height') ?? '0') ?? 0;

    if (width == 0 || height == 0) {
      final viewBox =
          svgElement.getAttribute('viewBox')?.split(RegExp(r'[ ,]+'));
      if (viewBox != null && viewBox.length == 4) {
        width = double.tryParse(viewBox[2]) ?? 0;
        height = double.tryParse(viewBox[3]) ?? 0;
      }
    }

    if (width == 0 || height == 0) {
      return "Não foi possível determinar as dimensões do SVG.";
    }

    final pageFormat = PdfPageFormat(
      width,
      height,
    );

    // Carregar a imagem da logo, se hasLogo for true
    pw.MemoryImage? logoImage;
    if (hasLogo && logoUrl != null && logoUrl.isNotEmpty) {
      final logoResponse = await http.get(Uri.parse(logoUrl));
      if (logoResponse.statusCode == 200) {
        logoImage = pw.MemoryImage(logoResponse.bodyBytes);
      } else {
        return "Erro ao carregar a imagem da logo. Código de status: ${logoResponse.statusCode}.";
      }
    }

    // **Construção da página do PDF**
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          // Definir tamanhos de fonte
          double maxMainFontSize = 84; // Ajuste este valor conforme necessário
          double alunoFontSize = (alunoInfo?['height'] ?? 0) * 0.5;
          double codeFontSize = (codeInfo?['height'] ?? 0) * 0.5;

          return pw.Stack(
            children: [
              // Renderiza o SVG como plano de fundo
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.SvgImage(
                  svg: svgContent,
                  width: width,
                  height: height,
                ),
              ),
              // Adiciona a logo, se houver
              if (hasLogo && logoImage != null && imageInfo != null)
                pw.Positioned(
                  left: imageInfo['posX'],
                  top: imageInfo['posY'],
                  child: pw.Image(
                    logoImage,
                    width: imageInfo['width'],
                    height: imageInfo['height'],
                  ),
                ),
              // Adiciona o texto "aluno", se o placeholder existir
              if (alunoInfo != null)
                pw.Positioned(
                  left: alunoInfo['posX'],
                  top: alunoInfo['posY'],
                  child: pw.Container(
                    width: alunoInfo['width'],
                    height: alunoInfo['height'],
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      aluno.trim(),
                      style: pw.TextStyle(
                        fontSize: alunoFontSize,
                        fontWeight: pw.FontWeight.normal,
                      ),
                      maxLines: 1,
                      textAlign: pw.TextAlign.left,
                    ),
                  ),
                ),
              // Adiciona o texto "mainText", se o placeholder existir
              if (mainInfo != null)
                pw.Positioned(
                  left: mainInfo['posX'],
                  top: mainInfo['posY'],
                  child: pw.Container(
                    width: mainInfo['width'],
                    height: mainInfo['height'],
                    alignment: pw.Alignment.topLeft,
                    child: pw.Text(
                      mainText.trim(),
                      style: pw.TextStyle(
                        fontSize: maxMainFontSize,
                        fontWeight: pw.FontWeight.normal,
                      ),
                      textAlign: pw.TextAlign.justify, // Justifica o texto
                    ),
                  ),
                ),
              // Adiciona o texto "authenticationCode"
              if (codeInfo != null)
                pw.Positioned(
                  left: codeInfo['posX'],
                  top: codeInfo['posY'],
                  child: pw.Container(
                    width: codeInfo['width'],
                    height: codeInfo['height'],
                    alignment: pw.Alignment.center, // Centralizado
                    child: pw.Text(
                      authenticationCode.trim(),
                      style: pw.TextStyle(
                        fontSize: codeFontSize,
                        fontWeight: pw.FontWeight.normal,
                      ),
                      maxLines: 1,
                      textAlign:
                          pw.TextAlign.center, // Alinhamento centralizado
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    final pdfSaved = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfSaved,
    );

    return "PDF gerado com sucesso!";
  } catch (e) {
    return "Erro ao gerar o PDF: $e";
  }
}
