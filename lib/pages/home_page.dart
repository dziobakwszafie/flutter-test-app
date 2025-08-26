import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controllers for input fields
  final TextEditingController _plateWidthController = TextEditingController(
    text: '534',
  );
  final TextEditingController _frontWidthController = TextEditingController(
    text: '2039',
  );
  final TextEditingController _backWidthController = TextEditingController(
    text: '2010',
  );

  final TextEditingController _desiredAngleDegreesController =
      TextEditingController(text: '1');
  final TextEditingController _desiredAngleMinutesController =
      TextEditingController(text: '33');

  // Calculated values
  double _currentAngleDegrees = 0;
  int _currentAngleMinutes = 0;

  double _differencePerSide = 0;
  double _frontTargetDistance = 0;
  double _backTargetDistance = 0;

  @override
  void initState() {
    super.initState();

    // Add listeners to trigger calculations when values change
    _plateWidthController.addListener(_onInputChanged);
    _frontWidthController.addListener(_onInputChanged);
    _backWidthController.addListener(_onInputChanged);
    _desiredAngleDegreesController.addListener(_onInputChanged);
    _desiredAngleMinutesController.addListener(_onInputChanged);

    _calculateCurrentAngle();
    _calculateTargetDistances();
  }

  void _onInputChanged() {
    _calculateCurrentAngle();
    _calculateTargetDistances();
  }

  /// Calculates the current angle from measured distances using arctangent.
  ///
  /// Mathematical formula used:
  /// - Current angle: α = arctan((d_larger - d_smaller) / plate_width)
  void _calculateCurrentAngle() {
    setState(() {
      // Step 1: Calculate current angle from measured values
      // Formula: angle = arctan((larger_distance - smaller_distance) / plate_width)
      double plateWidth = double.tryParse(_plateWidthController.text) ?? 1;
      double frontWidth = double.tryParse(_frontWidthController.text) ?? 1;
      double backWidth = double.tryParse(_backWidthController.text) ?? 1;
      double distanceDifference = (frontWidth - backWidth) / 2;
      double angleRadians = atan(distanceDifference / plateWidth);
      double angleDegrees = angleRadians * (180 / pi);
      _currentAngleDegrees = angleDegrees.truncate().toDouble();
      _currentAngleMinutes = ((angleDegrees % 1) * 60).toInt();
    });
  }

  /// Calculates target distances based on desired angle.
  ///
  /// This method performs the following calculations:
  /// 1. Tangent of the desired angle
  /// 2. Distance difference per side for the target angle
  /// 3. Target distances for both sides
  ///
  /// Mathematical formulas used:
  /// - Target distances: d_target = plate_width * tan(desired_angle)
  /// - Difference per side: Δd = (d_larger_target - d_smaller_target) / 2
  void _calculateTargetDistances() {
    setState(() {
      double plateWidth = double.tryParse(_plateWidthController.text) ?? 1;
      double frontWidth = double.tryParse(_frontWidthController.text) ?? 1;
      double backWidth = double.tryParse(_backWidthController.text) ?? 1;
      double axleWidth = (frontWidth + backWidth) / 2;

      // Step 2: Calculate tangent of desired angle
      // Formula: tan(angle) where angle = degrees + minutes/60
      double desiredAngleDegrees =
          double.tryParse(_desiredAngleDegreesController.text) ?? 1;
      double desiredAngleMinutes =
          double.tryParse(_desiredAngleMinutesController.text) ?? 1;
      double totalDesiredAngle =
          desiredAngleDegrees + (desiredAngleMinutes / 60.0);

      double tangent = tan(totalDesiredAngle * (pi / 180));

      // Step 3: Calculate distance difference per side
      // Formula: difference = plate_width * tan(desired_angle) / 2
      _differencePerSide = (plateWidth * tangent);

      // Step 4: Calculate target distances
      // Formula: target_distance = current_distance ± difference_per_side
      _frontTargetDistance = axleWidth + _differencePerSide;
      _backTargetDistance = axleWidth - _differencePerSide;
    });
  }

  @override
  void dispose() {
    _plateWidthController.removeListener(_onInputChanged);
    _frontWidthController.removeListener(_onInputChanged);
    _backWidthController.removeListener(_onInputChanged);
    _desiredAngleDegreesController.removeListener(_onInputChanged);
    _desiredAngleMinutesController.removeListener(_onInputChanged);

    _plateWidthController.dispose();
    _frontWidthController.dispose();
    _backWidthController.dispose();
    _desiredAngleDegreesController.dispose();
    _desiredAngleMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car alignment calculator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Measured Values Section
            _buildSection('Initial Values', [
              _buildInputRow('Plate Length', _plateWidthController, 'mm'),
              _buildInputRow('Front Distance', _frontWidthController, 'mm'),
              _buildInputRow('Back Distance', _backWidthController, 'mm'),
              _buildDisplayRow(
                'Current Angle',
                '${_currentAngleDegrees.toStringAsFixed(0)} deg $_currentAngleMinutes min',
              ),
              const SizedBox(height: 24),

              if (double.tryParse(_frontWidthController.text)! >
                  double.tryParse(_backWidthController.text)!)
                Image.asset('assets/images/toe-out.jpg')
              else if (double.tryParse(_frontWidthController.text)! <
                  double.tryParse(_backWidthController.text)!)
                Image.asset('assets/images/toe-in.jpg')
              else
                Image.asset('assets/images/zero-toe.jpg'),
            ]),

            const SizedBox(height: 24),

            // Distance Calculation Section
            _buildSection('Target Values', [
              _buildDoubleInputRow(
                'Desired Angle',
                _desiredAngleDegreesController,
                'deg',
                _desiredAngleMinutesController,
                'min',
              ),
              _buildDisplayRow(
                'Difference per Side',
                '${_differencePerSide.toStringAsFixed(1)} mm',
              ),
              _buildDisplayRow(
                'Front Distance',
                '${_frontTargetDistance.toStringAsFixed(1)} mm',
              ),
              _buildDisplayRow(
                'Back Distance',
                '${_backTargetDistance.toStringAsFixed(1)} mm',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.yellow.shade300),
              ),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                  suffixText: unit,
                  suffixStyle: TextStyle(color: Colors.grey.shade600),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleInputRow(
    String label,
    TextEditingController controller,
    String unit,
    TextEditingController controller2,
    String unit2,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.yellow.shade300),
              ),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                  suffixText: unit,
                  suffixStyle: TextStyle(color: Colors.grey.shade600),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.yellow.shade300),
              ),
              child: TextField(
                controller: controller2,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                  suffixText: unit2,
                  suffixStyle: TextStyle(color: Colors.grey.shade600),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
