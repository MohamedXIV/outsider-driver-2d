// Surface speech only. No travel, economy or knowledge effects are granted here.
VAR recognizes_driver = false
VAR district_name = "Outer Margin"
VAR destination = "Concourse Market"
-> travelling
=== travelling ===
{recognizes_driver:
"I remember this cab. It is good to see a familiar roof." # intent:travel_intro
- else:
"A little room to breathe. Thank you for stopping." # intent:travel_intro
}
-> choices
=== choices ===
+ [Ask about this part of the city.]
    "{district_name}. Every road here carries someone else's work. I mostly know the ways between my own stops." # intent:travel_city
    -> choices
+ [Ask how they are doing.]
    "Getting to {destination} is what matters to me today. I will manage the rest when I get there." # intent:travel_person
    -> choices
+ [Let the ride be quiet.]
    You leave the passenger a little quiet. # action:end_conversation
    -> END
