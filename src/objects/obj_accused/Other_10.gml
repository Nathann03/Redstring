///@description set messages to write
//scr_setmsg("* But the void stared back.", "obj_readable_other_10_0");

switch global.npc_name {
	case "catch_wallace":
	scr_setmsg("* Are you out of your goddamn mind?! I FOUND the body!", "obj_catch_framed_1");
	scr_nextmsg("* I came down at 7:45 in the morning with supplies and that's when I found him!", "obj_catch_framed_2");
	scr_nextmsg("* Why the hell would I report it if I killed him? You think I'm that stupid?", "obj_catch_framed_2");
	scr_nextmsg("* I was outside in the storm all night securing my boat.", "obj_catch_framed_2");
	scr_nextmsg("* Check the rope, check the boot prints, check the seaweed!", "obj_catch_framed_2");
	scr_nextmsg("* I was down at the dock fighting with rigging while Morgan was being killed.", "obj_catch_framed_2");
	scr_nextmsg("* I may've been at odds with him in the past, but I ain't a killer.", "obj_catch_framed_2");
	scr_nextmsg("* You've got the wrong man!", "obj_catch_framed_2");
	break;
	
	case "james_okoye":
	scr_setmsg("* What?! No! Absolutely not!", "obj_james_framed_1");
	scr_nextmsg("* I was in the equipment room running timed tests from 9 PM to midnight.", "obj_james_framed_2");
	scr_nextmsg("* Check the test tubes, check the security logs! Those tests require continuous presence.", "obj_james_framed_2");
	scr_nextmsg("* I couldn't have left for 15 minutes without ruining the entire sequence, much less MURDER my colleage.", "obj_james_framed_2");
	scr_nextmsg("* Then I went up to the beacon room at midnight, well after Morgan was already dead.", "obj_james_framed_2");
	scr_nextmsg("* I have a rock-solid alibi backed by physical evidence and digital records.", "obj_james_framed_2");
	scr_nextmsg("* You're making a catastrophic mistake.", "obj_james_framed_2");
	scr_nextmsg("* I didn't kill Morgan.", "obj_james_framed_2");
	scr_nextmsg("* I couldn't have killed Morgan.", "obj_james_framed_2");
	scr_nextmsg("* The timeline alone exonerates me!", "obj_james_framed_2");
	break;

	case "riley_chen":
	scr_setmsg("* What?! No no no no, I didn't... I couldn't...", "obj_riley_framed_1");
	scr_nextmsg("* I was in the beacon room! From 7 PM until nearly 8 in the morning!", "obj_riley_framed_2");
	scr_nextmsg("* Check the door logs, the security system, it's all there!", "obj_riley_framed_2");
	scr_nextmsg("* I never left, I was too scared of the storm to even go near the stairs!", "obj_riley_framed_2");
	scr_nextmsg("* The system logs every entry and exit, it proves I stayed there the whole time!", "obj_riley_framed_2");
	scr_nextmsg("* Why would I hurt Morgan?! He was the only one who was nice to me, who actually taught me things!", "obj_riley_framed_2");
	scr_nextmsg("* I loved working with him! Please, please check the security logs, they prove I couldn't have done this!", "obj_riley_framed_2");
	scr_nextmsg("* I didn't even know anything happened until Catch started yelling in the morning!", "obj_riley_framed_2");
	break;
	
	case "yuki_tanaka":
	global.accuse_npc = "yuki_tanaka"
	if (global.accuse_evidence == 0 && global.accuse_location == 0) {
		scr_setmsg("* Let me understand your theory. You're saying I killed Morgan?", "obj_yuki_winning_1");
		scr_nextmsg("* First, examine the body. He evidently died by blunt force trauma.", "obj_yuki_winning_2");
		scr_nextmsg("* Second, Morgan died in the tidal pool lab.", "obj_yuki_winning_2");
		scr_nextmsg("* That's where his body is, that's where the evidence places the murder.", "obj_yuki_winning_2");
		scr_nextmsg("* Your accusation doesn't align with basic forensic facts.", "obj_yuki_winning_2");
		scr_nextmsg("* I couldn't have done this the way you're describing.", "obj_yuki_winning_2");
		scr_nextmsg("*  Your logic is fundamentally flawed. The evidence contradicts you on multiple points.", "obj_yuki_winning_2");
		scr_nextmsg("* Are you even a detective?", "obj_yuki_winning_2");
	
	} else if (global.accuse_evidence == 1 && global.accuse_location == 0) {
		scr_setmsg("* This is embarrassing. For you.", "obj_yuki_winning_1");
		scr_nextmsg("* Morgan's body is in the tidal pool lab.", "obj_yuki_winning_2");
		scr_nextmsg("* It's been there for hours. The physical evidence proves it.", "obj_yuki_winning_2");
		scr_nextmsg("* And you think I killed him somewhere else and what-- carried him?", "obj_yuki_winning_2");
		scr_nextmsg("* Dragged a dead body through the facility without anyone noticing?", "obj_yuki_winning_2");
		scr_nextmsg("* That's absurd. Your accusation is logistically impossible.", "obj_yuki_winning_2");
		scr_nextmsg("* I'd suggest you review the crime scene before making accusations you can't support.", "obj_yuki_winning_2");
	
	} else if (global.accuse_evidence == 0 && global.accuse_location == 1) {
		scr_setmsg("* Really? That's your conclusion? This is rich.", "obj_yuki_winning_1");
		scr_nextmsg("* Look at the wound. Blunt force trauma to the back of the skull.", "obj_yuki_winning_2");
		scr_nextmsg("* You're suggesting I used that? That weapon would leave an entirely different injury pattern.", "obj_yuki_winning_2");
		scr_nextmsg("* Anyone with basic forensic knowledge could tell you that.", "obj_yuki_winning_2");
		scr_nextmsg("* Did you even examine the evidence, or did you just guess?", "obj_yuki_winning_2");
		scr_nextmsg("* This is pathetic detective work. Come back when you understand basic forensic analysis and spatial logic.", "obj_yuki_winning_2");
		
	} else if (global.accuse_evidence == 1 && global.accuse_location == 1) {
		scr_setmsg("* ...", "obj_yuki_confession_1");
		scr_nextmsg("* You're quite thorough.", "obj_yuki_confession_2");
		scr_nextmsg("* ...", "obj_yuki_confession_3");
		scr_nextmsg("* Morgan Blackwell was going to cost my company seven billion dollars in cleanup and environmental penalties.", "obj_yuki_confession_4");
		scr_nextmsg("* Seven billion.", "obj_yuki_confession_3");
		scr_nextmsg("* I gave him multiple opportunities to be reasonable.", "obj_yuki_confession_5");
		scr_nextmsg("* Simple data revisions, adjustments within acceptable margins of error. Standard industry practice.", "obj_yuki_confession_3");
		scr_nextmsg("* He refused. Called it 'scientific integrity.' Said he wouldn't compromise the data for any amount of pressure.", "obj_yuki_confession_6");
		scr_nextmsg("* Morgan chose principles over pragmatism, and that choice made him a liability.", "obj_yuki_confession_7");
		scr_nextmsg("* I was sent here to eliminate liabilities.", "obj_yuki_confession_3");
		scr_nextmsg("* I met him in the tidal pool lab at 10 PM when he went down for his sampling routine.", "obj_yuki_confession_8");
		scr_nextmsg("* I brought the wrench from the equipment room.", "obj_yuki_confession_9");
		scr_nextmsg("* One strike from behind.", "obj_yuki_confession_10");
		scr_nextmsg("* Clean.", "obj_yuki_confession_11");
		scr_nextmsg("* Efficient.", "obj_yuki_confession_11");
		scr_nextmsg("* ...", "obj_yuki_confession_12");
		scr_nextmsg("* I rinsed the wrench and left it there. Returned to the office to clean up. The storm provided excellent cover.", "obj_yuki_confession_12");
		scr_nextmsg("* ...", "obj_yuki_confession_12");
		scr_nextmsg("* ...", "obj_yuki_confession_12");
		scr_nextmsg("* I did what I was authorized to do. I'd like to speak with a lawyer now.", "obj_yuki_confession_12");
	}
	break;
}