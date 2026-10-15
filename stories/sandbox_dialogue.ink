// One reusable speech-act policy for all systemic ride offers.
// Variables come exclusively from validated SandboxWorld NPC/offer context.
// Local alien speech is *not* translated without language knowledge.
VAR understands_speaker = true
VAR knows_local_route = false
VAR recognizes_driver = false
VAR urgent = false
VAR temperament = "cautious"
VAR destination = "docks"
VAR purpose = "supplies"

-> intro

=== intro ===
{ understands_speaker:
    { recognizes_driver:
        "You again. I remember this cab; last time you got me there." # intent:request_trip
    - else:
        { urgent:
        { temperament == "cautious":
            "Please. I need a ride, but keep us away from trouble." # intent:request_trip
        - else:
            "I need a ride now. Can you move quickly?" # intent:request_trip
        }
    - else:
        { temperament == "cautious":
            "Are you taking passengers? I would rather keep this quiet." # intent:request_trip
        - else:
            "Hey, driver! Got room? I need to get moving." # intent:request_trip
        }
        }
    }
- else:
    { recognizes_driver:
        "Rru'ka shen vorr. Teka-rii?" The passenger recognizes your taxi, but their words remain untranslated. # intent:request_trip
    - else:
        "Rru'ka shen vorr. Teka-rii?" The stranger points at your taxi. # intent:request_trip
    }
}
+ [Ask where they need to go.]
    { understands_speaker:
        "I'm heading to {destination} for {purpose}." # intent:ask_destination
    - else:
        { knows_local_route:
            "Vrek shaa. Tir-ka." Your scanner recognizes the route marker for {destination}, but the other words remain untranslated. # intent:ask_destination
        - else:
            "Vrek shaa. Tir-ka." They gesture toward a location marker you cannot read aloud. # intent:ask_destination
        }
    }
    -> decide
+ [Agree to the trip.]
    You signal that you can take the fare. # action:accept_offer
    -> END
+ [Turn them down.]
    You refuse the fare. # action:decline_offer
    -> END

=== decide ===
+ [Agree to the trip.]
    You signal that you can take the fare. # action:accept_offer
    -> END
+ [Turn them down.]
    You refuse the fare. # action:decline_offer
    -> END
