# Routine Timers - Development Milestones

This directory contains the development milestones for the Routine Timers Garmin Connect IQ application. Each milestone is a self-contained deliverable with clear goals, checkboxes, success criteria, and testing procedures.

## Milestone Overview

| Milestone | Name | Est. Duration | Dependencies |
|-----------|------|---------------|--------------|
| M0 | [Project Setup & Scaffolding](./M0_project_setup.md) | 1-2 days | None |
| M1 | [Core Timer Engine](./M1_core_timer.md) | 2-3 days | M0 |
| M2 | [Multi-Step Routine Execution](./M2_multi_step_routines.md) | 2-3 days | M1 |
| M3 | [Timer User Interface](./M3_timer_ui.md) | 3-4 days | M2 |
| M4 | [Routine Storage & Selection](./M4_storage_selection.md) | 2-3 days | M3 |
| M5 | [Alerts & Haptic Feedback](./M5_alerts_feedback.md) | 1-2 days | M4 |
| M6 | [Background Service & Scheduling](./M6_background_scheduling.md) | 3-4 days | M5 |
| M7 | [Garmin Connect Mobile Integration](./M7_mobile_integration.md) | 3-4 days | M6 |
| M8 | [Multi-Device Testing & Polish](./M8_testing_polish.md) | 3-5 days | M7 |
| M9 | [Freemium & Store Submission](./M9_freemium_store.md) | 2-3 days | M8 |

**Total Estimated Duration:** 22-33 days (4-6 weeks)

---

## How to Use These Documents

### For Developers

1. **Work sequentially** - Each milestone builds on the previous one
2. **Check off tasks** as you complete them (use `[x]` in Markdown)
3. **Run all tests** in the Testing Checklist before marking a milestone complete
4. **Do not proceed** to the next milestone until all checkboxes are checked and success criteria are met

### For Project Managers

1. Use the checkbox completion rate to track progress
2. Each milestone has an **Acceptance Criteria** section - use this for milestone sign-off
3. Dependencies are listed - ensure they're met before starting a milestone

### For QA/Testers

1. Each milestone has a dedicated **Testing Checklist** section
2. Tests are designed to be run on the Garmin simulator first, then real devices
3. Edge cases and failure scenarios are explicitly listed

---

## Development Environment Requirements

Before starting M0, ensure you have:

- [ ] macOS, Windows, or Linux development machine
- [ ] [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) installed (latest version)
- [ ] Visual Studio Code with [Monkey C extension](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c)
- [ ] Garmin Connect IQ Simulator installed
- [ ] Garmin developer account (free at [developer.garmin.com](https://developer.garmin.com))
- [ ] Git for version control

---

## Quick Reference: Target Devices

### Phase 1 (MVP)
| Device | Resolution | Display |
|--------|------------|---------|
| Fenix 7S | 240×240 | MIP |
| Fenix 7 | 260×260 | MIP |
| Fenix 7X | 280×280 | MIP |
| Fenix 8 (43mm) | 416×416 | AMOLED |
| Fenix 8 (47mm) | 454×454 | AMOLED |
| Fenix 8 (51mm) | 484×484 | AMOLED |

---

## Definition of Done (Global)

A milestone is considered **DONE** when:

1. ✅ All checkboxes in the Implementation Checklist are checked
2. ✅ All tests in the Testing Checklist pass
3. ✅ All Success Criteria are met
4. ✅ Code compiles without errors for ALL target devices
5. ✅ Code has been reviewed (if working in a team)
6. ✅ Changes are committed to version control with descriptive messages

---

## Contact & Resources

- **Primary Spec Document:** [../app_spec.md](../app_spec.md)
- **Garmin Developer Docs:** https://developer.garmin.com/connect-iq/
- **Monkey C Reference:** https://developer.garmin.com/connect-iq/monkey-c/
- **Connect IQ Forums:** https://forums.garmin.com/developer/connect-iq/

---

*Last Updated: January 11, 2026*
