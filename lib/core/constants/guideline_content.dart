import 'package:flutter/material.dart';

/// A single expandable topic inside a guideline section, e.g.
/// "How to submit a proposal" with its detail steps collapsed underneath.
class GuidelineTopic {
  final String question;
  final List<String> steps;

  const GuidelineTopic({required this.question, required this.steps});
}

class GuidelineSection {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<GuidelineTopic> topics;

  const GuidelineSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.topics,
  });
}

/// Static guideline copy — mirrors the app's real navigation labels
/// (Home / Jobs / Workspace / Messages tabs, screen titles and button text)
/// so users can follow it step by step inside the actual UI.
class GuidelineContent {
  static const general = GuidelineSection(
    title: 'General',
    icon: Icons.info_outline_rounded,
    accentColor: Color(0xFF4F46E5),
    topics: [
      GuidelineTopic(
        question: 'What is a Freelancer account?',
        steps: [
          'A Freelancer account lets you browse jobs posted by clients, submit proposals, get hired through a contract, deliver work, and get paid inside WorkByte.',
          'You can build a profile with your skills, work experience, education, and portfolio so clients can evaluate you before hiring.',
        ],
      ),
      GuidelineTopic(
        question: 'What is a Client account?',
        steps: [
          'A Client account lets you post jobs, review proposals from freelancers, hire through a contract, and manage payments and deliverables inside WorkByte.',
          'You can review a freelancer\'s profile, portfolio, and past ratings before deciding to hire them.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I navigate the app?',
        steps: [
          'Home — an overview of recommended jobs or freelancers based on your account.',
          'Jobs — browse or post work, depending on your role.',
          'Workspace — manage every contract you currently have, active or completed.',
          'Messages — chat with clients or freelancers you\'re working with.',
        ],
      ),
      GuidelineTopic(
        question: 'How does messaging work?',
        steps: [
          'A new conversation starts as a request under the "Requests" tab in Messages.',
          'The other person must Accept it before you can chat freely — this helps keep out spam.',
        ],
      ),
      GuidelineTopic(
        question: 'How do payments and contracts work?',
        steps: [
          'Every contract is created and tracked inside WorkByte through Generate Contract and its milestones.',
          'Never agree to pay or get paid outside the app — WorkByte can\'t protect you if something goes wrong with an off-platform payment.',
        ],
      ),
      GuidelineTopic(
        question: 'How do ratings work?',
        steps: [
          'Once a contract is marked Completed, both sides can rate each other.',
          'This builds your trust score, which is what other users see when deciding whether to work with you — rate honestly.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I report a problem?',
        steps: [
          'Go to Settings > My Appeals to report a scam attempt, abuse, a disputed job, or to appeal a ban.',
        ],
      ),
    ],
  );

  static const freelancer = GuidelineSection(
    title: 'For Freelancers',
    icon: Icons.work_outline_rounded,
    accentColor: Color(0xFF059669),
    topics: [
      GuidelineTopic(
        question: 'How do I complete my profile?',
        steps: [
          'Fill in your profile manually, or open "Import from CV" to upload your CV.',
          'Review the suggested profile data it generates, then complete any field still marked "Still needed".',
        ],
      ),
      GuidelineTopic(
        question: 'How do I find jobs to apply to?',
        steps: [
          'Open the Jobs tab to see "Available Jobs".',
          'Use the search bar, or open the "Filter & Sort" sheet (Sort By, Project Type, Experience Level) to narrow results down.',
          'Tap a job to open its detail page and check both the "Details" and "Terms" tabs.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I know if a job fits me?',
        steps: [
          'On a job\'s role, tap "Analyze My Fit" to see how well your profile matches before applying.',
          'Not ready to apply yet? Tap the bookmark icon on the job card to save it for later.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I submit a proposal?',
        steps: [
          'Tap "Apply for Role" on the job you want to open Submit Proposal.',
          'Write a clear Cover Letter (50–1000 characters).',
          'Set your Proposed Budget (if the role allows negotiation) and Estimated Duration.',
          'Attach supporting files if needed, then tap "Submit Proposal".',
          'You can track everything you\'ve sent under the "Applied" tab in Jobs.',
        ],
      ),
      GuidelineTopic(
        question: 'What happens after I get hired?',
        steps: [
          'The client generates and sends you a contract — review the agreed budget, payment structure, and milestones before work begins.',
          'Open the Workspace tab to see "Working Spaces" and manage every active contract from there.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I submit my work?',
        steps: [
          'Inside the contract, tap "Submit Work" once it\'s ready for review.',
          'If the client requests changes, make them and tap "Resubmit Work".',
        ],
      ),
      GuidelineTopic(
        question: 'How does a contract get completed?',
        steps: [
          'Once the client approves your submission, the contract status changes to Completed and payment for that milestone or contract is settled.',
          'After that, tap "Rate This Client" to leave your review.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I message a client?',
        steps: [
          'Use the "Messages" card inside an active contract, or reply from a job\'s conversation, to talk with a client about the work.',
        ],
      ),
    ],
  );

  static const client = GuidelineSection(
    title: 'For Clients',
    icon: Icons.storefront_outlined,
    accentColor: Color(0xFFD97706),
    topics: [
      GuidelineTopic(
        question: 'How do I post a new job?',
        steps: [
          'Tap the "+" button in the bottom navigation to start "Post new job" — it\'s a 3-step wizard.',
          'Step 1 – Job Detail: fill in Title, Description (minimum 50 words), Experience Level, Estimated Duration, and Project Deadline.',
          'Step 2 – Role & Skills: choose Individual or Team, then set each role\'s Title, Description, Budget Type (Fixed or Negotiable), Amount & Currency, and required Skills.',
          'Step 3 – Attachments (optional): attach briefs, mockups, or reference files, or skip this step.',
          'Review the Summary and publish — the job goes live once posted.',
          'The wizard autosaves as a draft, so you can leave and resume anytime from "Open drafts".',
        ],
      ),
      GuidelineTopic(
        question: 'How do I review proposals?',
        steps: [
          'Open the job from the Jobs tab to see incoming proposals.',
          'Check each freelancer\'s profile, portfolio, and past reviews before deciding.',
          'Not sure yet? Tap "Message" on a proposal to ask the freelancer questions before hiring.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I hire a freelancer?',
        steps: [
          'Open "Generate Contract" on the proposal you want to accept.',
          'Set the Agreed Budget, Payment Structure (Full Payment or Milestone Based), and Payment Timing.',
          'Break the work into Milestones if needed, then tap "Generate Contract PDF" and "Send to Freelancer".',
        ],
      ),
      GuidelineTopic(
        question: 'How do I manage active work?',
        steps: [
          'Track everything from the Workspace tab under "Working Spaces".',
          'Contract status chips show Active, Under Review, Revision Requested, Completed, Cancelled, or Disputed.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I review submitted work?',
        steps: [
          'When a freelancer submits work, review it inside the contract.',
          'Tap "Approve" if it meets the agreement, or "Revision" to send it back with notes.',
          'Approving marks the contract Completed and settles payment for that milestone — this can\'t be undone, so review carefully first.',
        ],
      ),
      GuidelineTopic(
        question: 'How does a contract get completed?',
        steps: [
          'Once you approve the final submission, the contract status changes to Completed.',
          'After that, tap "Rate This Freelancer" to leave your review.',
        ],
      ),
      GuidelineTopic(
        question: 'How do I cancel a contract?',
        steps: [
          'If a contract needs to stop early, use "Cancel Contract" inside the workspace rather than leaving it unresolved.',
        ],
      ),
    ],
  );
}
