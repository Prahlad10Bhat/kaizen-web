import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../services/feedback_service.dart';
import 'package:kaizen/utils/snackbar_utils.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _messageController = TextEditingController();

  String _selectedCategory = 'Bug Report';
  int _rating = 0;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Bug Report',
    'Feature Request',
    'Design Suggestion',
    'General Feedback',
    'Other',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      SnackbarUtils.showCustomSnackBar(context, 'Please enter your feedback message', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FeedbackService.submitFeedback(
        title: _selectedCategory,
        message: _messageController.text.trim(),
        category: _selectedCategory,
        email: null, // Email removed from UI
        rating: _rating,
      );

      if (!mounted) return;

      _messageController.clear();

      setState(() {
        _rating = 0;
        _selectedCategory = 'Bug Report';
        _isSubmitting = false;
      });

      SnackbarUtils.showCustomSnackBar(context, 'Feedback submitted successfully', isSuccess: true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      SnackbarUtils.showCustomSnackBar(context, 'Failed to submit feedback', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback',
              style: GoogleFonts.sora(
                color: theme.textTheme.displayLarge?.color,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),
            Text(
              'Help us improve KAIZEN by sharing your thoughts.',
              style: GoogleFonts.inter(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const Gap(60),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          theme.dividerTheme.color ?? Colors.transparent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(
                        context,
                        'How would you rate your experience?',
                      ),
                      const Gap(16),
                      Row(
                        children: List.generate(5, (index) {
                          final starValue = index + 1;

                          return IconButton(
                            onPressed: () {
                              setState(() {
                                _rating =
                                    _rating == starValue ? 0 : starValue;
                              });
                            },
                            icon: Icon(
                              _rating > index ? Icons.star_rounded : Icons.star_border_rounded,
                              color: _rating > index
                                  ? Colors.amber
                                  : theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.2),
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const Gap(40),
                      _buildLabel(context, 'Category'),
                      const Gap(16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _categories
                            .map((cat) => _buildCategoryChip(cat))
                            .toList(),
                      ),
                      const Gap(40),
                      _buildLabel(context, 'Message'),
                      const Gap(16),
                      _buildTextField(
                        controller: _messageController,
                        hint: 'Share your thoughts or report an issue...',
                        maxLines: 6,
                      ),
                      const Gap(40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Submit Feedback',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.dividerTheme.color ?? Colors.transparent,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : theme.textTheme.bodyMedium?.color,
            fontSize: 13,
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }
}
