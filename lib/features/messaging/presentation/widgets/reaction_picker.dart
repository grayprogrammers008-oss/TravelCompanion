import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Enhanced Reaction Picker with Multiple Categories
/// Shows a beautiful emoji picker with categories and search
class ReactionPicker extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });

  /// Show reaction picker as bottom sheet
  static Future<String?> show(
    BuildContext context, {
    required Function(String emoji) onEmojiSelected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionPicker(
        onEmojiSelected: (emoji) {
          onEmojiSelected(emoji);
          Navigator.pop(context, emoji);
        },
      ),
    );
  }

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Emoji categories with comprehensive selections
  final Map<String, List<EmojiData>> _emojiCategories = {
    'Frequently Used': [
      EmojiData('👍', 'thumbs up'),
      EmojiData('❤️', 'red heart'),
      EmojiData('😂', 'face with tears of joy'),
      EmojiData('😮', 'face with open mouth'),
      EmojiData('🎉', 'party popper'),
      EmojiData('🔥', 'fire'),
      EmojiData('👏', 'clapping hands'),
      EmojiData('💯', 'hundred points'),
    ],
    'Smileys': [
      EmojiData('😀', 'grinning face'),
      EmojiData('😃', 'grinning face with big eyes'),
      EmojiData('😄', 'grinning face with smiling eyes'),
      EmojiData('😁', 'beaming face'),
      EmojiData('😆', 'grinning squinting face'),
      EmojiData('😅', 'grinning with sweat'),
      EmojiData('🤣', 'rolling on floor laughing'),
      EmojiData('😂', 'tears of joy'),
      EmojiData('🙂', 'slightly smiling'),
      EmojiData('😊', 'smiling with smiling eyes'),
      EmojiData('😇', 'smiling with halo'),
      EmojiData('🥰', 'smiling with hearts'),
      EmojiData('😍', 'smiling with heart eyes'),
      EmojiData('🤩', 'star struck'),
      EmojiData('😘', 'face blowing a kiss'),
      EmojiData('😗', 'kissing face'),
      EmojiData('😚', 'kissing with closed eyes'),
      EmojiData('😙', 'kissing with smiling eyes'),
      EmojiData('🥲', 'smiling with tear'),
      EmojiData('😋', 'yummy'),
      EmojiData('😛', 'face with tongue'),
      EmojiData('😜', 'winking with tongue'),
      EmojiData('🤪', 'zany face'),
      EmojiData('😝', 'squinting with tongue'),
    ],
    'Gestures': [
      EmojiData('👍', 'thumbs up'),
      EmojiData('👎', 'thumbs down'),
      EmojiData('👏', 'clapping hands'),
      EmojiData('🙌', 'raising hands'),
      EmojiData('👐', 'open hands'),
      EmojiData('🤲', 'palms up together'),
      EmojiData('🤝', 'handshake'),
      EmojiData('🙏', 'folded hands'),
      EmojiData('✍️', 'writing hand'),
      EmojiData('💪', 'flexed biceps'),
      EmojiData('🦾', 'mechanical arm'),
      EmojiData('👌', 'ok hand'),
      EmojiData('🤌', 'pinched fingers'),
      EmojiData('🤏', 'pinching hand'),
      EmojiData('✌️', 'victory hand'),
      EmojiData('🤞', 'crossed fingers'),
      EmojiData('🤟', 'love you gesture'),
      EmojiData('🤘', 'sign of horns'),
      EmojiData('👈', 'backhand index pointing left'),
      EmojiData('👉', 'backhand index pointing right'),
      EmojiData('👆', 'backhand index pointing up'),
      EmojiData('👇', 'backhand index pointing down'),
      EmojiData('☝️', 'index pointing up'),
      EmojiData('✋', 'raised hand'),
    ],
    'Hearts': [
      EmojiData('❤️', 'red heart'),
      EmojiData('🧡', 'orange heart'),
      EmojiData('💛', 'yellow heart'),
      EmojiData('💚', 'green heart'),
      EmojiData('💙', 'blue heart'),
      EmojiData('💜', 'purple heart'),
      EmojiData('🖤', 'black heart'),
      EmojiData('🤍', 'white heart'),
      EmojiData('🤎', 'brown heart'),
      EmojiData('💔', 'broken heart'),
      EmojiData('❤️‍🔥', 'heart on fire'),
      EmojiData('❤️‍🩹', 'mending heart'),
      EmojiData('💕', 'two hearts'),
      EmojiData('💞', 'revolving hearts'),
      EmojiData('💓', 'beating heart'),
      EmojiData('💗', 'growing heart'),
      EmojiData('💖', 'sparkling heart'),
      EmojiData('💘', 'heart with arrow'),
      EmojiData('💝', 'heart with ribbon'),
    ],
    'Celebrations': [
      EmojiData('🎉', 'party popper'),
      EmojiData('🎊', 'confetti ball'),
      EmojiData('🎈', 'balloon'),
      EmojiData('🎆', 'fireworks'),
      EmojiData('🎇', 'sparkler'),
      EmojiData('✨', 'sparkles'),
      EmojiData('🎁', 'wrapped gift'),
      EmojiData('🎀', 'ribbon'),
      EmojiData('🎂', 'birthday cake'),
      EmojiData('🍰', 'shortcake'),
      EmojiData('🧁', 'cupcake'),
      EmojiData('🥳', 'partying face'),
      EmojiData('🎊', 'confetti'),
      EmojiData('🎖️', 'military medal'),
      EmojiData('🏆', 'trophy'),
      EmojiData('🥇', 'gold medal'),
      EmojiData('🥈', 'silver medal'),
      EmojiData('🥉', 'bronze medal'),
    ],
    'Travel': [
      EmojiData('✈️', 'airplane'),
      EmojiData('🚀', 'rocket'),
      EmojiData('🛫', 'airplane departure'),
      EmojiData('🛬', 'airplane arrival'),
      EmojiData('🗺️', 'world map'),
      EmojiData('🧳', 'luggage'),
      EmojiData('🎒', 'backpack'),
      EmojiData('🏖️', 'beach with umbrella'),
      EmojiData('🏝️', 'desert island'),
      EmojiData('🗼', 'tokyo tower'),
      EmojiData('🗽', 'statue of liberty'),
      EmojiData('🏰', 'castle'),
      EmojiData('🏔️', 'snow capped mountain'),
      EmojiData('⛰️', 'mountain'),
      EmojiData('🏕️', 'camping'),
      EmojiData('⛺', 'tent'),
      EmojiData('🚗', 'automobile'),
      EmojiData('🚕', 'taxi'),
      EmojiData('🚙', 'sport utility vehicle'),
      EmojiData('🚌', 'bus'),
      EmojiData('🚎', 'trolleybus'),
      EmojiData('🏎️', 'racing car'),
      EmojiData('🚂', 'locomotive'),
      EmojiData('🚆', 'train'),
    ],
    'Objects': [
      EmojiData('💯', 'hundred points'),
      EmojiData('🔥', 'fire'),
      EmojiData('⚡', 'lightning'),
      EmojiData('💫', 'dizzy'),
      EmojiData('⭐', 'star'),
      EmojiData('🌟', 'glowing star'),
      EmojiData('✅', 'check mark'),
      EmojiData('❌', 'cross mark'),
      EmojiData('❓', 'question mark'),
      EmojiData('❗', 'exclamation mark'),
      EmojiData('💡', 'light bulb'),
      EmojiData('💎', 'gem stone'),
      EmojiData('🎯', 'direct hit'),
      EmojiData('📍', 'round pushpin'),
      EmojiData('📌', 'pushpin'),
      EmojiData('📸', 'camera'),
      EmojiData('📷', 'camera with flash'),
      EmojiData('📱', 'mobile phone'),
      EmojiData('💰', 'money bag'),
      EmojiData('💵', 'dollar banknote'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _emojiCategories.keys.length,
      vsync: this,
    );
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<EmojiData> get _filteredEmojis {
    if (_searchQuery.isEmpty) return [];

    final allEmojis = _emojiCategories.values.expand((list) => list).toList();
    return allEmojis
        .where((emoji) => emoji.description.contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMd),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Row(
              children: [
                const Text(
                  'Choose Reaction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppTheme.neutral600,
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search emojis...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.neutral500),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.neutral500),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Category tabs (hidden when searching)
          if (_searchQuery.isEmpty) ...[
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryTeal,
              unselectedLabelColor: AppTheme.neutral500,
              indicatorColor: AppTheme.primaryTeal,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: _emojiCategories.keys.map((category) {
                return Tab(text: category);
              }).toList(),
            ),
            const Divider(height: 1),
          ],

          // Emoji grid
          Expanded(
            child: _searchQuery.isEmpty
                ? TabBarView(
                    controller: _tabController,
                    children: _emojiCategories.values.map((emojis) {
                      return _buildEmojiGrid(emojis);
                    }).toList(),
                  )
                : _buildEmojiGrid(_filteredEmojis),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid(List<EmojiData> emojis) {
    if (emojis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.neutral300,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No emojis found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: AppTheme.spacingSm,
        mainAxisSpacing: AppTheme.spacingSm,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return _EmojiButton(
          emoji: emoji.emoji,
          onTap: () => widget.onEmojiSelected(emoji.emoji),
        );
      },
    );
  }
}

/// Emoji data with description for search
class EmojiData {
  final String emoji;
  final String description;

  EmojiData(this.emoji, this.description);
}

/// Enhanced Emoji Button with Animation
class _EmojiButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.onTap,
  });

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Center(
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }
}
