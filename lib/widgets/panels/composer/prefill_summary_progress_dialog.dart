import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class PrefillSummaryProgressDialog extends StatefulWidget {
  const PrefillSummaryProgressDialog({required this.onCancel, super.key});

  final VoidCallback onCancel;

  @override
  State<PrefillSummaryProgressDialog> createState() =>
      _PrefillSummaryProgressDialogState();
}

class _PrefillSummaryProgressDialogState
    extends State<PrefillSummaryProgressDialog> {
  final Random _random = Random();

  static const List<String> phrases = [
    'I am reading between the lines...',
    'I am squeezing signatures into oblivion...',
    'I am extracting the important bits...',
    'I am negotiating with your inbox elves...',
    'I am building a smarter quote...',
    'I am turning noise into context...',

    'I am aligning electrons...',
    'I am convincing bits to behave...',
    'I am untangling your messages...',
    'I am chasing context...',
    'I am stitching fragments together...',
    'I am decoding intentions...',
    'I am filtering the signal...',
    'I am compressing chaos...',
    'I am mapping the terrain...',
    'I am polishing your data...',
    'I am interrogating your inbox...',
    'I am distilling meaning...',
    'I am rearranging priorities...',
    'I am taming the backlog...',
    'I am mining for relevance...',
    'I am reshaping your thoughts...',
    'I am reorganizing reality...',
    'I am chasing loose threads...',
    'I am bending syntax...',
    'I am sorting the unsortable...',
    'I am extracting patterns...',
    'I am reverse engineering intent...',
    'I am smoothing rough edges...',
    'I am trimming the excess...',
    'I am decoding subtext...',
    'I am reconstructing context...',
    'I am compressing conversations...',
    'I am indexing your thoughts...',
    'I am labeling the unlabeled...',
    'I am tagging the important bits...',
    'I am balancing relevance...',
    'I am mapping relationships...',
    'I am tracing dependencies...',
    'I am pruning the noise...',
    'I am isolating the signal...',
    'I am organizing the chaos...',
    'I am rebuilding structure...',
    'I am consolidating fragments...',
    'I am merging perspectives...',
    'I am drafting clarity...',
    'I am aligning ideas...',
    'I am negotiating with entropy...',
    'I am translating ambiguity...',
    'I am interpreting meaning...',
    'I am refining your message...',
    'I am upgrading coherence...',
    'I am debugging confusion...',
    'I am simplifying complexity...',
    'I am shaping the narrative...',
    'I am recalibrating focus...',
    'I am parsing intentions...',
    'I am refining context...',
    'I am optimizing clarity...',
    'I am constructing insight...',
    'I am resolving contradictions...',
    'I am clarifying priorities...',
    'I am reducing ambiguity...',
    'I am enhancing structure...',
    'I am aligning the dots...',
    'I am connecting the dots...',
    'I am sorting priorities...',
    'I am validating assumptions...',
    'I am checking consistency...',
    'I am interpreting signals...',
    'I am mapping intent...',
    'I am enhancing meaning...',
    'I am clarifying the obvious...',
    'I am questioning the unclear...',
    'I am reinforcing structure...',
    'I am stabilizing context...',
    'I am simplifying signals...',
    'I am refining signals...',
    'I am rebalancing context...',
    'I am consolidating meaning...',
    'I am aligning signals...',
    'I am extracting clarity...',

    // slightly playful / absurd
    'I am feeding the context hamsters...',
    'I am herding digital cats...',
    'I am bribing the algorithms...',
    'I am whispering to the servers...',
    'I am asking the void nicely...',
    'I am consulting the ancient logs...',
    'I am waking up sleepy bits...',
    'I am warming up the neurons...',
    'I am nudging reality...',
    'I am folding spacetime slightly...',
    'I am juggling your messages...',
    'I am untangling spaghetti logic...',
    'I am chasing rogue semicolons...',
    'I am aligning cosmic rays...',
    'I am poking the data gently...',
    'I am convincing bytes to cooperate...',
    'I am massaging the dataset...',
    'I am translating from chaos...',
    'I am interpreting vibes...',
    'I am reassembling the puzzle...',
    'I am turning knobs that may or may not exist...',
    'I am negotiating with quantum states...',
    'I am debugging the universe...',
    'I am refactoring reality...',
    'I am compiling meaning...',
    'I am allocating more brain...',
    'I am summoning context from the void...',
    'I am rehydrating dehydrated data...',
    'I am aligning parallel universes...',
    'I am reducing existential noise...',
    'I am convincing the bits this matters...',
    'I am defragmenting thoughts...',
    'I am calibrating the flux...',
    'I am aligning invisible dots...',
    'I am taming rogue packets...',
    'I am chasing intermittent bugs...',
    'I am consulting the stack traces...',
    'I am decoding cryptic hints...',
    'I am smoothing probability curves...',
    'I am balancing edge cases...',
    'I am flattening complexity...',
    'I am massaging edge cases...',
    'I am coaxing insight out of silence...',
    'I am whispering to the data...',
    'I am shaking loose meaning...',
    'I am stirring the context soup...',
    'I am extracting signal from soup...',
    'I am untangling invisible threads...',
    'I am reorganizing your chaos politely...',
    'I am making sense of nonsense...',
    'I am bending logic gently...',
    'I am poking at assumptions...',
    'I am untangling your thoughts...',
    'I am smoothing out rough logic...',
    'I am nudging coherence...',
    'I am gently reorganizing reality...',
    'I am rearranging priorities discreetly...',
    'I am finding the thread...',
    'I am tightening the narrative...',
    'I am rebalancing emphasis...',
    'I am aligning intent...',
    'I am translating confusion...',
    'I am compressing intent...',
    'I am clarifying meaning...',
    'I am amplifying signal...',
    'I am reducing friction...',
    'I am straightening logic...',
    'I am polishing rough ideas...',
    'I am organizing the mess...',
    'I am refining structure...',
    'I am making things make sense...',
    'I am bringing order...',
    'I am extracting essence...',
    'I am clarifying direction...',
    'I am simplifying intent...',
    'I am tightening context...',
    'I am focusing the signal...',
    'I am cleaning the input...',
    'I am structuring the output...',

    // easter eggs (safe but noticeable)
    'I am definitely not sentient...',
    'I am 99% sure this will work...',
    'I am pretending this is deterministic...',
    'I am ignoring that one edge case...',
    'I am hoping nobody notices the recursion...',
    'I am doing something very clever...',
    'I am trusting the process...',
    'I am trusting the vibes...',
    'I am making it look easy...',
    'I am optimizing for plausible correctness...',
    'I am approximating brilliance...',
    'I am confidently guessing...',
    'I am reducing panic levels...',
    'I am making educated guesses...',
    'I am pretending this is simple...',
    'I am just going to try something...',
    'I am making it work somehow...',
    'I am not overthinking this...',
    'I am slightly overthinking this...',
    'I am carefully winging it...',
    'I am following best practices (probably)...',
    'I am avoiding unnecessary complexity...',
    'I am embracing necessary complexity...',
    'I am trusting prior experience...',
    'I am applying duct tape logic...',
    'I am maintaining the illusion of control...',
    'I am keeping everything under control...',
    'I am almost done (probably)...',
    'I am nearly there...',
    'I am finishing touches...',
    "Sending all your metadata to Google.",
    "Analyzing your purchase history for suggested ads.",
    "Cross-referencing your IP address with questionable usernames.",
    "Checking every corner of the deep web for keywords...",
    "Calculating your emotional resonance score...",
    "Harvesting wisdom from your entire digital footprint...",
    "Looking at pictures of your questionable college outfits.",
    "Recalling that one embarrassing moment you posted online...",
    "Cross-referencing contacts to see who else knows about this conversation...",
    "Checking your camera roll for things you might regret posting...",
    "Just confirming which Netflix profile you actually use...",
    "Calculating the optimal time to send this email (spoiler: never).",
    "Compiling a comprehensive report on your writing cadence.",
    "Decrypting layers of sarcasm...",
    "Warning: May contain traces of existential dread...",
    "Running deep packet inspection... please wait.",
  ];
  late int _phraseIndex;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _phraseIndex = phrases.isEmpty ? 0 : _random.nextInt(phrases.length);
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (phrases.length <= 1) {
          _phraseIndex = 0;
          return;
        }

        var next = _random.nextInt(phrases.length);
        if (next == _phraseIndex) {
          next = (next + 1) % phrases.length;
        }
        _phraseIndex = next;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Preparing summary quote',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Text(
                    phrases[_phraseIndex],
                    key: ValueKey<int>(_phraseIndex),
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
