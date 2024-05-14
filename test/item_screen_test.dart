import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:developer' as developer;

void main() {
  group('getPriceData', () {
    test('should update price data correctly', () async {
      // Arrange
      final String priceByUom =
          '{"1": {"pcs": "10.00", "box": "50.00"}, "2": {"pcs": "12.00", "box": "60.00"}}';
      Map<int, Map<String, double>> priceData = {};

      // Implement the getPriceData function within the test
      Future<void> getPriceData() async {
        try {
          Map<String, dynamic> decodedData = jsonDecode(priceByUom);
          priceData = {};

          decodedData.forEach((key, value) {
            int areaId = int.tryParse(key) ?? 0;
            if (value is Map<String, dynamic>) {
              Map<String, double> areaPrices = {};
              value.forEach((uom, price) {
                if (price is String) {
                  double parsedPrice =
                      double.tryParse(price.replaceAll(',', '')) ?? 0.0;
                  areaPrices[uom] = parsedPrice;
                }
              });
              priceData[areaId] = areaPrices;
            }
          });
        } catch (e) {
          developer.log('Error decoding price data: $e', error: e);
        }
      }

      // Act
      await getPriceData();

      // Assert
      expect(priceData, {
        1: {'pcs': 10.0, 'box': 50.0},
        2: {'pcs': 12.0, 'box': 60.0},
      });
    });
  });

  group('retrievePriceByUomUsingAreaId', () {
    test('should retrieve the correct price data based on area ID', () {
      // Arrange
      final List<Map<String, dynamic>> areas = [
        {
          'id': 1,
          'name': 'Kuching',
          'priceByUom': '{"1": {"pcs": "10.00", "box": "50.00"}}',
        },
        {
          'id': 2,
          'name': 'Sabah',
          'priceByUom': '{"2": {"pcs": "12.00", "box": "60.00"}}',
        },
        {
          'id': 3,
          'name': 'Bintulu',
          'priceByUom': '{"3": {"pcs": "15.00", "box": "75.00"}}',
        },
      ];

      Map<int, Map<String, double>> priceData = {};
      String uom = '';
      double price = 0.0;
      String priceDataByArea = '';

      // Implement the retrievePriceByUomUsingAreaId function within the test
      void retrievePriceByUomUsingAreaId(int areaId) {
        final area = areas.firstWhere((area) => area['id'] == areaId);
        final String priceByUom = area['priceByUom'];

        final decodedData = jsonDecode(priceByUom) as Map<String, dynamic>;
        final areaData = decodedData[areaId.toString()];

        if (areaData != null && areaData is Map<String, dynamic>) {
          final Map<String, double> areaPrices = {};
          areaData.forEach((uom, price) {
            if (price is String) {
              double parsedPrice =
                  double.tryParse(price.replaceAll(',', '')) ?? 0.0;
              areaPrices[uom] = parsedPrice;
            }
          });

          priceData[areaId] = areaPrices;

          if (areaPrices.isNotEmpty) {
            final firstEntry = areaPrices.entries.first;
            uom = firstEntry.key;
            price = firstEntry.value;
            priceDataByArea = jsonEncode(areaPrices);
          }
        }
      }

      // Act
      retrievePriceByUomUsingAreaId(1);

      // Assert
      expect(priceData[1], {'pcs': 10.0, 'box': 50.0});
      expect(uom, 'pcs');
      expect(price, 10.0);
      expect(priceDataByArea, '{"pcs":10.0,"box":50.0}');

      // Act
      retrievePriceByUomUsingAreaId(2);

      // Assert
      expect(priceData[2], {'pcs': 12.0, 'box': 60.0});
      expect(uom, 'pcs');
      expect(price, 12.0);
      expect(priceDataByArea, '{"pcs":12.0,"box":60.0}');

      // Act
      retrievePriceByUomUsingAreaId(3);

      // Assert
      expect(priceData[3], {'pcs': 15.0, 'box': 75.0});
      expect(uom, 'pcs');
      expect(price, 15.0);
      expect(priceDataByArea, '{"pcs":15.0,"box":75.0}');
    });
  });
}
