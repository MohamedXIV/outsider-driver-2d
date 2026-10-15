// One reusable speech-act policy for all systemic ride offers.
// Variables come exclusively from validated SandboxWorld NPC/offer context.
// Local alien speech is *not* translated without language knowledge.
VAR understands_speaker = true
VAR urgent = false
VAR temperament = "cautious"
VAR destination = "docks"
VAR purpose = "supplies"

=== intro ===
# intent:request_trip
{ understands_speaker:
    { urgent:
        { temperament == "cautious":
            "Please. I need a ride, but keep us away from trouble."
        - else:
            "I need a ride now. Can you move quickly?"
        }
    - else:
        { temperament == "cautious":
            "Are you taking passengers? I would rather keep this quiet."
        - else:
            "Hey, driver! Got room? I need to get moving."
        }
    }
- else:
    "Rru'ka shen vorr. Teka-rii?" The stranger points at your taxi.
}
+ [Ask where they need to go.]
    # intent:ask_destination
    { understands_speaker:
        "I'm heading to {destination} for {purpose}."
    - else:
        "Vrek shaa. Tir-ka." They gesture toward a location marker you cannot read aloud.
    }
    -> decide
+ [Agree to the trip.]
    # action:accept_offer
    -> END
+ [Turn them down.]
    # action:decline_offer
    -> END

=== decide ===
+ [Agree to the trip.]
    # action:accept_offer
    -> END
+ [Turn them down.]
    # action:decline_offer
    -> END
