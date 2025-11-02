import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../models/report.dart';
import '../widgets/consistent_app_bar.dart';

class ReportUserScreen extends StatefulWidget {
  final Map<String, dynamic> userToReport;
  
  const ReportUserScreen({
    super.key,
    required this.userToReport,
  });

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedReason;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      setState(() {
        _errorMessage = 'Please select a reason for reporting';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _apiService.reportUser(
        widget.userToReport['uid'] ?? widget.userToReport['id'],
        _selectedReason!,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit report: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildReasonOption(String reason, String displayText) {
    final isSelected = _selectedReason == reason;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: reason,
        groupValue: _selectedReason,
        onChanged: (value) {
          setState(() {
            _selectedReason = value;
            _errorMessage = null;
          });
        },
        title: Text(
          displayText,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : Colors.black87,
          ),
        ),
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.userToReport['displayName'] ?? 
                    widget.userToReport['username'] ?? 
                    'Unknown User';

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Report User',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: widget.userToReport['profilePicture'] != null 
                          ? NetworkImage(widget.userToReport['profilePicture'])
                          : null,
                      child: widget.userToReport['profilePicture'] == null
                          ? Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reporting: $userName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.userToReport['username'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '@${widget.userToReport['username']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Report reason section
            const Text(
              'Why are you reporting this user?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select the most appropriate reason for your report. This helps us take appropriate action.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Reason options
            _buildReasonOption(
              ReportReason.sexualContent,
              ReportReason.getDisplayText(ReportReason.sexualContent),
            ),
            _buildReasonOption(
              ReportReason.violentContent,
              ReportReason.getDisplayText(ReportReason.violentContent),
            ),
            _buildReasonOption(
              ReportReason.hatefulContent,
              ReportReason.getDisplayText(ReportReason.hatefulContent),
            ),
            _buildReasonOption(
              ReportReason.harmfulContent,
              ReportReason.getDisplayText(ReportReason.harmfulContent),
            ),
            _buildReasonOption(
              ReportReason.spamContent,
              ReportReason.getDisplayText(ReportReason.spamContent),
            ),
            _buildReasonOption(
              ReportReason.childAbuse,
              ReportReason.getDisplayText(ReportReason.childAbuse),
            ),
            
            const SizedBox(height: 24),
            
            // Description section
            const Text(
              'Additional Details (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide any additional context that will help us understand the issue better.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Describe what happened...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'What happens next?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Your report will be reviewed by our team\n'
                    '• We will investigate the reported behavior\n'
                    '• Appropriate action will be taken if needed\n'
                    '• You will not be notified of the outcome for privacy reasons',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
