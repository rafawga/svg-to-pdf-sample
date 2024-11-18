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
    String mainText, // Texto principal
    String authenticationCode // Código de autenticação
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

    // Substituição de placeholders nas variáveis mainText e authenticationCode
    Map<String, String> variables = {
      '{aluno}': aluno,
      '{c-type}': type,
      '{teacher}': teacher,
      '{date}': date,
      '{duration}': duration,
      '{c-name}': curso,
      '{code}': code,
    };

    // Substitui variáveis no mainText
    variables.forEach((placeholder, value) {
      mainText = mainText.replaceAll(placeholder, value);
    });

    // Substitui variáveis no authenticationCode
    variables.forEach((placeholder, value) {
      authenticationCode = authenticationCode.replaceAll(placeholder, value);
    });

    // Parse do SVG
    final svgXml = xml.XmlDocument.parse(svgContent);

    // Encontrar e processar os placeholders gráficos

    // Encontrar 'aluno_placeholder'
    xml.XmlElement? alunoPlaceholder;
    final alunoElements = svgXml.findAllElements('g').where(
          (element) => element.getAttribute('id') == 'aluno_placeholder',
        );
    if (alunoElements.isNotEmpty) {
      alunoPlaceholder = alunoElements.first;
    } else {
      alunoPlaceholder = null;
    }

    double alunoPosX = 0, alunoPosY = 0, alunoWidth = 0, alunoHeight = 0;
    if (alunoPlaceholder != null) {
      final alunoRectElement = alunoPlaceholder.findElements('rect').first;
      alunoWidth = double.parse(alunoRectElement.getAttribute('width') ?? '0');
      alunoHeight = double.parse(alunoRectElement.getAttribute('height') ?? '0');
      final alunoTransform = alunoRectElement.getAttribute('transform') ?? '';
      final alunoTranslateMatch =
          RegExp(r'translate\(([\d\.]+)[,\s]+([\d\.]+)\)')
              .firstMatch(alunoTransform);

      if (alunoTranslateMatch != null) {
        alunoPosX = double.parse(alunoTranslateMatch.group(1) ?? '0');
        alunoPosY = double.parse(alunoTranslateMatch.group(2) ?? '0');
      }
    }

    // Encontrar 'main_placeholder'
    xml.XmlElement? mainPlaceholder;
    final mainElements = svgXml.findAllElements('g').where(
          (element) => element.getAttribute('id') == 'main_placeholder',
        );
    if (mainElements.isNotEmpty) {
      mainPlaceholder = mainElements.first;
    } else {
      mainPlaceholder = null;
    }

    double mainPosX = 0, mainPosY = 0, mainWidth = 0, mainHeight = 0;
    if (mainPlaceholder != null) {
      final mainRectElement = mainPlaceholder.findElements('rect').first;
      mainWidth = double.parse(mainRectElement.getAttribute('width') ?? '0');
      mainHeight = double.parse(mainRectElement.getAttribute('height') ?? '0');
      final mainTransform = mainRectElement.getAttribute('transform') ?? '';
      final mainTranslateMatch =
          RegExp(r'translate\(([\d\.]+)[,\s]+([\d\.]+)\)')
              .firstMatch(mainTransform);

      if (mainTranslateMatch != null) {
        mainPosX = double.parse(mainTranslateMatch.group(1) ?? '0');
        mainPosY = double.parse(mainTranslateMatch.group(2) ?? '0');
      }
    }

    // **Novo código: Encontrar 'image_placeholder'**
    xml.XmlElement? imagePlaceholder;
    final imageElements = svgXml.findAllElements('g').where(
          (element) => element.getAttribute('id') == 'image_placeholder',
        );
    if (imageElements.isNotEmpty) {
      imagePlaceholder = imageElements.first;
    } else {
      imagePlaceholder = null;
    }

    double imagePosX = 0, imagePosY = 0, imageWidth = 0, imageHeight = 0;
    if (imagePlaceholder != null) {
      final imageRectElement = imagePlaceholder.findElements('rect').first;
      imageWidth = double.parse(imageRectElement.getAttribute('width') ?? '0');
      imageHeight = double.parse(imageRectElement.getAttribute('height') ?? '0');
      final imageTransform = imageRectElement.getAttribute('transform') ?? '';
      final imageTranslateMatch =
          RegExp(r'translate\(([\d\.]+)[,\s]+([\d\.]+)\)')
              .firstMatch(imageTransform);

      if (imageTranslateMatch != null) {
        imagePosX = double.parse(imageTranslateMatch.group(1) ?? '0');
        imagePosY = double.parse(imageTranslateMatch.group(2) ?? '0');
      }
    }

    // Encontrar 'code_placeholder'
    xml.XmlElement? codePlaceholder;
    final codeElements = svgXml.findAllElements('g').where(
          (element) => element.getAttribute('id') == 'code_placeholder',
        );
    if (codeElements.isNotEmpty) {
      codePlaceholder = codeElements.first;
    } else {
      codePlaceholder = null;
    }

    double codePosX = 0, codePosY = 0, codeWidth = 0, codeHeight = 0;
    if (codePlaceholder != null) {
      final codeRectElement = codePlaceholder.findElements('rect').first;
      codeWidth = double.parse(codeRectElement.getAttribute('width') ?? '0');
      codeHeight = double.parse(codeRectElement.getAttribute('height') ?? '0');
      final codeTransform = codeRectElement.getAttribute('transform') ?? '';
      final codeTranslateMatch =
          RegExp(r'translate\(([\d\.]+)[,\s]+([\d\.]+)\)')
              .firstMatch(codeTransform);

      if (codeTranslateMatch != null) {
        codePosX = double.parse(codeTranslateMatch.group(1) ?? '0');
        codePosY = double.parse(codeTranslateMatch.group(2) ?? '0');
      }
    }

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
          double alunoFontSize = alunoHeight * 0.5;
          double codeFontSize = codeHeight * 0.5; // Ajuste conforme necessário

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
              // **Adiciona a logo, se houver**
              if (hasLogo && logoImage != null && imagePlaceholder != null)
                pw.Positioned(
                  left: imagePosX,
                  top: imagePosY,
                  child: pw.Image(
                    logoImage,
                    width: imageWidth,
                    height: imageHeight,
                  ),
                ),
              // Adiciona o texto "aluno", se o placeholder existir
              if (alunoPlaceholder != null)
                pw.Positioned(
                  left: alunoPosX,
                  top: alunoPosY,
                  child: pw.Container(
                    width: alunoWidth,
                    height: alunoHeight,
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      aluno,
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
              if (mainPlaceholder != null)
                pw.Positioned(
                  left: mainPosX,
                  top: mainPosY,
                  child: pw.Container(
                    width: mainWidth,
                    height: mainHeight,
                    alignment: pw.Alignment.topLeft,
                    child: pw.Text(
                      mainText,
                      style: pw.TextStyle(
                        fontSize: maxMainFontSize,
                        fontWeight: pw.FontWeight.normal,
                      ),
                      textAlign: pw.TextAlign.left,
                    ),
                  ),
                ),
              // Adiciona o texto "authenticationCode"
              if (codePlaceholder != null)
                pw.Positioned(
                  left: codePosX,
                  top: codePosY,
                  child: pw.Container(
                    width: codeWidth,
                    height: codeHeight,
                    alignment: pw.Alignment.center, // Centralizado
                    child: pw.Text(
                      authenticationCode,
                      style: pw.TextStyle(
                        fontSize: codeFontSize,
                        fontWeight: pw.FontWeight.normal,
                      ),
                      maxLines: 1,
                      textAlign: pw.TextAlign.center, // Alinhamento centralizado
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
