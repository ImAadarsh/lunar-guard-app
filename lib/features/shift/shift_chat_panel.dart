import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../models/shift_chat_message.dart';
import '../../theme/app_colors.dart';
import '../../theme/lunar_theme_extension.dart';
import '../../utils/format_datetime.dart';
import '../../utils/maps_links.dart';
import '../../widgets/status_chip.dart';
import 'shift_chat_controller.dart';

class ShiftChatPanel extends StatefulWidget {
  const ShiftChatPanel({
    super.key,
    required this.shiftId,
    this.siteLabel,
  });

  final int shiftId;
  final String? siteLabel;

  @override
  State<ShiftChatPanel> createState() => _ShiftChatPanelState();
}

class _ShiftChatPanelState extends State<ShiftChatPanel> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  ShiftChatController? _chat;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chat ??= context.read<ShiftChatController>();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_bind);
  }

  @override
  void didUpdateWidget(covariant ShiftChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shiftId != widget.shiftId) {
      Future.microtask(_bind);
    }
  }

  Future<void> _bind() async {
    if (!mounted) return;
    final chat = context.read<ShiftChatController>();
    final userId = context.read<AuthController>().profile?.id;
    chat.setCurrentUserId(userId);
    chat.setVisible(true);
    await chat.bindShift(widget.shiftId);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chat?.setVisible(false);
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    final chat = context.read<ShiftChatController>();
    final err = await chat.sendMessage(text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      _input.clear();
      _scrollToBottom();
    }
  }

  Future<void> _sendPing() async {
    final chat = context.read<ShiftChatController>();
    final err = await chat.sendPing();
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ping sent to admin.')),
      );
      _scrollToBottom();
    }
  }

  Future<void> _openPingMap(ShiftChatMessage message) async {
    final lat = message.lat;
    final lng = message.lng;
    if (lat == null || lng == null) return;
    final ok = await openGoogleMaps(lat: lat, lng: lng, label: 'Ping location');
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  String _messageTime(ShiftChatMessage message) {
    final dt = message.createdAt?.toLocal();
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final chat = context.watch<ShiftChatController>();
    final thread = chat.thread;

    final isUpcoming = thread == null || thread.isUpcoming;
    final isActive = thread?.isActive == true;
    final isClosed = thread?.isClosed == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'Shift chat',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.chat_bubble_rounded
                          : Icons.chat_bubble_outline_rounded,
                      color: isActive ? AppColors.success : lunar.mutedText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.siteLabel ??
                                thread?.siteLabel ??
                                'Shift #${widget.shiftId}',
                            style: t.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (thread?.lastMessageAt != null)
                            Text(
                              'Last message ${formatUkDateTime(thread!.lastMessageAt)}',
                              style: t.bodySmall?.copyWith(color: lunar.mutedText),
                            ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: isActive
                          ? 'Live'
                          : isClosed
                              ? 'Closed'
                              : 'Upcoming',
                      tone: isActive
                          ? StatusTone.success
                          : isClosed
                              ? StatusTone.neutral
                              : StatusTone.warning,
                    ),
                  ],
                ),
                if (chat.loading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ] else if (chat.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    chat.error!,
                    style: t.bodySmall?.copyWith(color: AppColors.danger),
                  ),
                ],
                if (isUpcoming && !chat.loading) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: lunar.highlightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lunar.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock_rounded,
                            color: lunar.mutedText, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chat opens when you check in at the site.',
                            style: t.bodyMedium?.copyWith(
                              color: lunar.mutedText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isUpcoming) ...[
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: lunar.highlightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lunar.border),
                    ),
                    child: chat.messages.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                isClosed
                                    ? 'No messages in this shift chat.'
                                    : 'No messages yet. Say hello to ops.',
                                style: t.bodySmall?.copyWith(
                                  color: lunar.mutedText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: chat.messages.length,
                            itemBuilder: (_, i) {
                              final msg = chat.messages[i];
                              return _MessageBubble(
                                message: msg,
                                isOwn: chat.isOwnMessage(msg),
                                timeLabel: _messageTime(msg),
                                onOpenMap: msg.isPing &&
                                        msg.lat != null &&
                                        msg.lng != null
                                    ? () => _openPingMap(msg)
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
                if (isActive) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: chat.sending ? null : _sendPing,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.location_on_rounded, size: 22),
                    label: const Text('Ping Admin'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          enabled: !chat.sending,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Message ops…',
                            filled: true,
                            fillColor: lunar.tileBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: lunar.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: lunar.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: chat.sending ? null : _sendMessage,
                        icon: chat.sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
                if (isClosed) ...[
                  const SizedBox(height: 12),
                  Text(
                    'This shift chat is closed — message history is read-only.',
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ],
                if (thread != null && thread.isUpcoming) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Check in to unlock messaging and pings.',
                    style: t.bodySmall?.copyWith(color: lunar.mutedText),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.timeLabel,
    this.onOpenMap,
  });

  final ShiftChatMessage message;
  final bool isOwn;
  final String timeLabel;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lunar = context.lunar;
    final align = isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isOwn
        ? AppColors.primary.withValues(alpha: 0.85)
        : lunar.tileBackground;
    final textColor = isOwn ? AppColors.onDark : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isOwn && (message.senderName?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                message.senderName!,
                style: t.labelSmall?.copyWith(
                  color: lunar.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isOwn ? 14 : 4),
                bottomRight: Radius.circular(isOwn ? 4 : 14),
              ),
              border: isOwn ? null : Border.all(color: lunar.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isPing) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: isOwn ? AppColors.silver : AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Location ping',
                        style: t.labelMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (message.body != null && message.body!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      message.body!,
                      style: t.bodyMedium?.copyWith(color: textColor),
                    ),
                  ],
                  if (onOpenMap != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onOpenMap,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isOwn ? AppColors.silver : lunar.linkColor,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('View on map'),
                    ),
                  ],
                ] else
                  Text(
                    message.body ?? '',
                    style: t.bodyMedium?.copyWith(color: textColor),
                  ),
                if (message.pending) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sending…',
                    style: t.labelSmall?.copyWith(
                      color: isOwn
                          ? AppColors.silverMuted
                          : lunar.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (timeLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                timeLabel,
                style: t.labelSmall?.copyWith(color: lunar.mutedText),
              ),
            ),
        ],
      ),
    );
  }
}
