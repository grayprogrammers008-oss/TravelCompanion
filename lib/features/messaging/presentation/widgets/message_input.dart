import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Message Input Widget
/// Text field for composing and sending messages
class MessageInput extends StatefulWidget {
  final Function(String message) onSend;
  final VoidCallback? onAttachmentTap;
  final bool isEnabled;
  final String? replyToMessage;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onAttachmentTap,
    this.isEnabled = true,
    this.replyToMessage,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.isEnabled) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator
            if (widget.replyToMessage != null) _buildReplyIndicator(),

            // Input field
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  if (widget.onAttachmentTap != null)
                    IconButton(
                      onPressed: widget.isEnabled ? widget.onAttachmentTap : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.primaryTeal,
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                  if (widget.onAttachmentTap != null)
                    const SizedBox(width: AppTheme.spacingXs),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral50,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(
                          color: AppTheme.neutral200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              enabled: widget.isEnabled,
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: AppTheme.neutral400,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd,
                                  vertical: AppTheme.spacingSm,
                                ),
                                fillColor: Colors.transparent,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),

                          // Character counter (only shown when near limit)
                          if (_controller.text.length > 1800)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppTheme.spacingXs,
                                bottom: AppTheme.spacingSm,
                              ),
                              child: Text(
                                '${_controller.text.length}/2000',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _controller.text.length > 2000
                                      ? AppTheme.error
                                      : AppTheme.neutral400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: AppTheme.spacingXs),

                  // Send button
                  _buildSendButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build reply indicator
  Widget _buildReplyIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryPale,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyToMessage ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.neutral700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: AppTheme.neutral600,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Build send button
  Widget _buildSendButton() {
    final canSend = _hasText &&
        widget.isEnabled &&
        _controller.text.length <= 2000;

    return GestureDetector(
      onTap: canSend ? _handleSend : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: canSend
              ? AppTheme.primaryGradient
              : null,
          color: canSend ? null : AppTheme.neutral200,
          shape: BoxShape.circle,
          boxShadow: canSend ? AppTheme.shadowTeal : null,
        ),
        child: Icon(
          Icons.send_rounded,
          color: canSend ? Colors.white : AppTheme.neutral400,
          size: 20,
        ),
      ),
    );
  }
}
