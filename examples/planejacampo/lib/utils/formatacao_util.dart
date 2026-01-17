import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class FormatacaoUtil {
  static final FormatacaoUtil _instance = FormatacaoUtil._internal();

  late NumberFormat _numberFormat;
  late String _decimalSeparator;
  late String _thousandSeparator;

  // Construtor da classe com opção de definir o Locale
  factory FormatacaoUtil([Locale? locale]) {
    if (locale != null) {
      _instance._updateLocale(locale);
    }
    return _instance;
  }

  FormatacaoUtil._internal() {
    _numberFormat = NumberFormat.decimalPattern();
    _decimalSeparator = _numberFormat.symbols.DECIMAL_SEP;
    _thousandSeparator = _numberFormat.symbols.GROUP_SEP;
  }

  static FormatacaoUtil get instance => _instance;

  NumberFormat get numberFormat => _numberFormat;

  String get decimalSeparator => _decimalSeparator;

  String get thousandSeparator => _thousandSeparator;

  // Formatação de números com abreviação (1.5M, 1.5k, etc.)
  String formatNumberWithAbbreviation(double value) {
    if (value >= 1000000) {
      return '${_numberFormat.format(value / 1000000)}M'; // Milhões (1.5M)
    } else if (value >= 1000) {
      return '${_numberFormat.format(value / 1000)}k'; // Milhares (1.5k)
    } else {
      return _numberFormat.format(value); // Valor padrão
    }
  }

  // Função para formatar números com duas casas decimais
  static String formatNumberWithTwoDecimalPlaces(double value) {
    final NumberFormat numberFormat = NumberFormat("#,##0.00", Intl.defaultLocale);
    return numberFormat.format(value);
  }

  // Função para formatar números no padrão do Locale
  String formatNumber(double value) {
    return _numberFormat.format(value);
  }

  // Conversão de string para número, respeitando o separador decimal do Locale
  double parseNumber(String value) {
    // Remove any thousand separators
    String normalizedValue = value.replaceAll(_thousandSeparator, '');
    
    // Replace the decimal separator with a dot
    normalizedValue = normalizedValue.replaceAll(_decimalSeparator, '.');
    
    // Try to parse the normalized value
    return double.parse(normalizedValue);
  }

  // Formatação de strings simples (não alterada)
  String formatText(String value) {
    return value;
  }

  // Formatação de datas
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Máscara de CPF/CNPJ, baseada no tipo de pessoa e locale
  static MaskTextInputFormatter getDocumentoMaskFormatter(
      String tipoPessoa, String languageTag) {
    if (tipoPessoa == 'Pessoa Física') {
      if (languageTag == 'pt-BR') {
        return MaskTextInputFormatter(
            mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
      } else if (languageTag == 'en-US') {
        return MaskTextInputFormatter(
            mask: '###-##-####', filter: {"#": RegExp(r'[0-9]')});
      }
    } else if (tipoPessoa == 'Pessoa Jurídica') {
      if (languageTag == 'pt-BR') {
        return MaskTextInputFormatter(
            mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});
      } else if (languageTag == 'en-US') {
        return MaskTextInputFormatter(
            mask: '##-#######', filter: {"#": RegExp(r'[0-9]')});
      }
    }
    return MaskTextInputFormatter(mask: '#############################');
  }

  // Atualização do locale dinamicamente
  void _updateLocale(Locale newLocale) {
    _numberFormat = NumberFormat.decimalPattern(newLocale.toString());
    _decimalSeparator = _numberFormat.symbols.DECIMAL_SEP;
    _thousandSeparator = _numberFormat.symbols.GROUP_SEP;
  }

  void updateLocale(Locale newLocale) {
    _updateLocale(newLocale);
  }

  // Controlador para campos monetários com máscara
  static MoneyMaskedTextController getMaskedTextController(double initialValue) {
    final String decimalSeparator = _instance._numberFormat.symbols.DECIMAL_SEP;
    final String thousandSeparator = _instance._numberFormat.symbols.GROUP_SEP;

    // Verificar se o valor inicial está dentro de um intervalo válido
    if (initialValue < 0) {
      initialValue = 0;
    }

    return MoneyMaskedTextController(
      decimalSeparator: decimalSeparator,
      thousandSeparator: thousandSeparator,
      initialValue: initialValue,
      precision: 2,  // Precisão para duas casas decimais
    );
  }

// Controlador para campos numéricos inteiros sem casas decimais
  // Controlador para campos numéricos inteiros sem casas decimais
  static MoneyMaskedTextController getIntegerMaskedTextController(int initialValue) {
    final String thousandSeparator = _instance._numberFormat.symbols.GROUP_SEP;

    // Verificar se o valor inicial está dentro de um intervalo válido
    if (initialValue < 0) {
      initialValue = 0;
    }

    return MoneyMaskedTextController(
      decimalSeparator: '', // Sem separador decimal
      thousandSeparator: thousandSeparator,
      initialValue: initialValue.toDouble(), // Converte o inteiro para double, já que o controlador trabalha com double
      precision: 0,  // Precisão para 0 casas decimais (somente inteiros)
    );
  }



  // Função para aceitar apenas entradas decimais com o separador correto
  TextInputFormatter get decimalInputFormatter => _decimalTextInputFormatter(_decimalSeparator);

  // Função para definir formatação de entrada de decimais com base no separador do locale
  TextInputFormatter _decimalTextInputFormatter(String decimalSeparator) {
    return TextInputFormatter.withFunction(
      (TextEditingValue oldValue, TextEditingValue newValue) {
        // Permitir que o campo seja apagado completamente
        if (newValue.text.isEmpty) {
          return newValue;
        }

        // Limitar para números decimais e permitir múltiplos dígitos antes e após o decimal
        final String separator = RegExp.escape(decimalSeparator);
        final RegExp regExp = RegExp(r'^\d{1,12}(' + separator + r'\d{0,2})?$');

        if (regExp.hasMatch(newValue.text)) {
          return newValue;
        }

        // Caso não seja válido, retorna o valor antigo
        return oldValue;
      },
    );
  }

  static String formatDateMonthYear(DateTime date) {
    return DateFormat('MMMM y').format(date);
  }

  static bool hasValidPosition(GlobalKey key) {
    if (key.currentContext == null) {
      return false;
    }
    final RenderBox? renderBox = key.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return false;
    }
    final position = renderBox.localToGlobal(Offset.zero);
    // Verifica se a posição está dentro dos limites da tela
    return position.dx >= 0 && position.dy >= 0;
  }
}