// Shared off-duty encounter; NPC/time context comes from SandboxWorld.
// Ink produces text and speech-act tags, never changes relationship state.
VAR is_late = false
VAR is_cautious = false
VAR understands_speaker = true

-> meetup

=== meetup ===
{ is_late:
    The contact glances at the clock. You have arrived later than promised.
- else:
    You meet by the neighborhood kiosk, away from the taxi's meter.
}
{ understands_speaker:
    { is_cautious:
        "I usually keep to myself. It's different talking without a fare between us."
    - else:
        "Good to see you outside the cab. I wanted a quiet conversation."
    }
- else:
    "Rru'ka vell." The familiar passenger gestures toward a seat. Their words remain untranslated.
}
+ [Sit and listen for a while.]
    You give them your attention as the city carries on nearby. # meeting:listen
    -> END
+ [Exchange a few words, then excuse yourself.]
    You keep it friendly but short. # meeting:brief
    -> END
+ [Leave before the conversation gets going.]
    You leave the meeting place early. # meeting:leave
    -> END
