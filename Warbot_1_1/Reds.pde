///////////////////////////////////////////////////////////////////////////
//
// The code for the red team
// ===========================
//
///////////////////////////////////////////////////////////////////////////


//------CUSTOM MESSAGE FOR THE RED TEAM ARE DEFINED HERE----------//
  
  final int ASK_FOR_JOINING_COALITION = 1000;
  // message used to invite someone to a coalition. It goes hand in hand with multiples arguments. 
  // args[0] : type of coalition 
  // args[1] : role offered for this coalition 
  // args[2] : colour to secure the message
  
  final int RESPOND_TO_COALITION_OFFER = 1001;
  //message used in order to accept or decline a coalition offer. 
  // args[0] : 0 = Refusal | 1 = Compliance
  // args[1] : colour to secure the message
  
  final int CONFIRM_COALITION_FORMATION =  1002; 
  //message used in order to confirm the creation of the coalition. 
  // arg[0] : type of coalition 
  // arg[1] : role in this coalition, depending on the type of coalition
  // args[2] : colour to secure the message
  
  final int INFORM_ABOUT_DISSOLVING_COALITION = 1003;
  // message used in order to dissolve a coalition. If the transmitter and the receiver belong to the same coalition, the coalition is canceled and the receiver transmit the message too. 
  // args[0] : colour to secure the message
  
  final int HI_THERE = 1004;
  //Message used in order to say hi to another unit. The main purpose of this is to regularly check if the members of a coalition is still alive and transmit its position to other
  //arg[0] = x coordinate of the emitting unit 
  //arg[1] = y coordinateof the emitting unit 
  //args[2] : colour to secure the message

//------END OF CUSTOM MESSAGE DEFINITION ----------//


class RedTeam extends Team {
  
  PVector base1, base2;

  // coordinates of the 2 bases, chosen in the rectangle with corners
  // (width/2, 0) and (width, height-100)
  RedTeam() {
    // first base
    base1 = new PVector(width/2 + 300, (height - 100)/2 - 150);
    // second base
    base2 = new PVector(width/2 + 300, (height - 100)/2 + 150);
  }  
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the red bases
//
///////////////////////////////////////////////////////////////////////////
class RedBase extends Base {
  //
  // constructor
  // ===========
  //
  RedBase(PVector p, color c, Team t) {
    super(p, c, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the base
  //
  void setup() {
    // 6 harvesters, 3 explorers, 2 rockets launchers
    brain[5].x = 6;
    brain[5].z = 3;
    brain[5].y = 2;
  }
  
  void chooseNewRobot(){

    // creates new robots depending on energy and the state of brain[5]
    if ((brain[5].x > 0) && (energy >= 1000 + harvesterCost)) {
      // 1st priority = creates harvesters 
      if (newHarvester()){
          brain[5].x--;
      }
    } else if ((brain[5].y > 0) && (energy >= 1000 + launcherCost)) {
      // 2nd priority = creates rocket launchers 
      if (newRocketLauncher()){
          brain[5].y--;
       }
    } else if ((brain[5].z > 0) && (energy >= 1000 + explorerCost)) {
      // 3rd priority = creates explorers 
      if (newExplorer()){
        brain[5].z--;
      }     
    } 
    else if(energy>5000){
        ArrayList<Seed> seeds = perceiveSeeds(friend);
        ArrayList<Robot> robots = perceiveRobots(friend, HARVESTER);
        if(seeds!=null && robots!=null){
          if(seeds.size()>70 && robots.size()>4){ //lot of seed and harvester -> Rocket Launcher
              newRocketLauncher();
              System.out.println("new rocket");

            }
          else if(seeds.size()<40){ //no seed -> Harvester 
              newHarvester();
              System.out.println("new harv");
          }
          else{ //is ok : explo
              newExplorer();
              System.out.println("new explo");
            }
        }  
        newHarvester();
        System.out.println("new harv");
    }
   

  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    // handle received messages 
    handleMessages();
    chooseNewRobot();
    // creates new bullets and fafs if the stock is low and enought energy
    if ((bullets < 10) && (energy > 1000))
      newBullets(50);
    if ((bullets < 10) && (energy > 1000))
      newFafs(10);

    // if ennemy rocket launcher in the area of perception
    Robot bob = (Robot)minDist(perceiveRobots(ennemy));
    if (bob != null) {
      // call for help
      //System.out.println("Base " + who + " is calling for help at " + pos.x + ", " + pos.y); 
      float[] args = new float[2];
      args[0] = who;
      args[1] = colour;
      // for each explorer in range
      ArrayList<Robot> explorers = perceiveRobots(friend, EXPLORER);  
      if (explorers != null) {
        for (int i = 0; i < explorers.size(); i++) {
          // ask the type of their coalition (0 no coalition, 1 attack coalition, 2 harvest coalition)
             sendMessage(explorers.get(i).who, 140, args);
        }
      }
      
      heading = towards(bob);
      // launch a faf if no friend robot on the trajectory...
      if (perceiveRobotsInCone(friend, heading) == null)
        launchFaf(bob);
    }
  }

  //
  // handleMessage
  // =============
  // > handle messages received since last activation 
  //
  void handleMessages() {
    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      msg = messages.get(i);
      if (msg.type == ASK_FOR_ENERGY) {
        // if the message is a request for energy
        if (energy > 1000 + msg.args[0]) {
          // gives the requested amount of energy only if at least 1000 units of energy left after
          giveEnergy(msg.alice, msg.args[0]);
        }
      } else if (msg.type == ASK_FOR_BULLETS) {
        // if the message is a request for energy
        if (energy > 1000 + msg.args[0] * bulletCost) {
          // gives the requested amount of bullets only if at least 1000 units of energy left after
          giveBullets(msg.alice, msg.args[0]);
        }
      } else if (msg.type == 141 && msg.args[1] == colour) {
        // if the explorer is in an attack coalition send message to order defense
          if (msg.args[0] == 1) { // that means brain[1].z == 1 for the explorer
            float[] arg = new float[3];
            arg[0] = pos.x;  // position of the sender
            arg[1] = pos.y;  // position of the sender
            arg[2] = colour;  // colour of the sender
            sendMessage(msg.alice, 14, arg); // base sends a message to ask the coalition to come help
            
          }
      }
    }
    // clear the message queue
    flushMessages();
  }
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the red explorers
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   4.x = (0 = exploration | 1 = go back to base)
//   4.y = (0 = no target | 1 = locked target)
//   4.z = (0 = basic explorer | 1 = chief of attack coalition | 2 = chief of convey coalition)
//   0.x / 0.y = coordinates of the target
//   0.z = type of the target
//
//   1.x [if chief of attack coalition] = number of rockets in the coalition (2 max)
//   1.x / 1.y [if chief of convey coalition] = coordinate of the nomad havester search point 
//   1.z = type of coalition (0 = None | 1 = Attack Coalition | 2 = Convey coalition)
//   2.x / 2.y [if chief of a convey coalition] = last coordinate of the sedentary harvester  
//   2.z =  waiting for coalition to complete (0 = no proposal; 1 = First only say yes; 2 = second only say yes ; 3 = both accepted) 
//
//   3.x = coalition expiration default duration;
//   3.y = current coalition timer ;
//   3.z = coalition delta time between each tick for the timer ;
//
//map of the aquaintances:
//   ??? if the explorer is a chief of convey coalition
//     0 = id of the sedentary harvester
//     1 = id of the nomad harvester 
///////////////////////////////////////////////////////////////////////////
class RedExplorer extends Explorer {
  //
  // constructor
  // ===========
  //
  RedExplorer(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
    // 33% of chance to create an explorer of one those types : basic, convey, attack 
    brain[4].z = int(random(3));
    System.out.println("Explorer of type " + brain[4].z + " is born");
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
    brain[1].x=0;
    brain[3].x = 100;
    brain[3].y = 100;
    brain[3].z = 0.01;
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
void go() {
    
    handleMessages();
   
    // if food to deposit or too few energy
    if (( (carryingFood > 200) && brain[1].z != 2 ) || (energy < 100))
      // time to go back to base
      brain[4].x = 1;

    // depending on the state of the robot
    if(brain[1].z == 1) //ATTACK COALITION BEHAVIOR
    {
      //In coalition, the explorer will attempt to locate enemies, by classing them in priority, and then transmit that target to the team's rocket launchers
      LocateEnemy();
      if(energy < 50) //if the explorer has too low of an energy and its going to die, we dissolve the coalition
      {
        //DISSOLVE COALITION
        //System.out.println("Explorer : dissolving coalition");
        System.out.println("Explorer "+who+" : dissolving coalition");
        float[] arg = new float[2];
        arg[0]=who;
        arg[1]=colour;
        if(acquaintances[3]>=0)
        { 
          //System.out.println("Explorer "+who+" : sending dissolve coalition message to rocket "+acquaintances[3]);
          sendMessage(acquaintances[3], 13, arg);
          acquaintances[3]=-1;
          brain[1].x--;  
        }
        if(acquaintances[4]>=0)
        {
          //System.out.println("Explorer "+who+" : sending dissolve coalition message to rocket "+acquaintances[4]);
          sendMessage(acquaintances[4], 13, arg);
          acquaintances[4]=-1;
          brain[1].x--;
        }
        brain[1].z=0;
      }
      if(energy < 100)
      {
        brain[4].x = 1;
      }
      else if(brain[4].y == 1) //if a target has been set, we move towards the target to give rockets time to attack
      {
        tryToMoveForward();
      }
      else{ //if no target found, we perform standard behavior
        if (brain[4].x == 1) {
          // go back to base...
          goBackToBase();
        } else {
          // ...or explore randomly
          randomMove(45);
        }
      }
    }
    
    else if(brain[1].z == 2) //CONVEY COALITION BEHAVIOR
    {
      checkUponHarvesters();
      
      if(carryingFood < 50){
        joinNomadHarvester();
      } else {
        joinSedentaryHarvester();
      }
      decreaseCoalitionTimer(); //we decrease the coalition timer 
    } 
    
    else if ( brain[1].z == 0 && brain[4].z == 2){ //THE EXPLORER TYPE IS CONVEY CHIEF AND NOT IN A COALITION NOW
      //stay near the base and doing job offer to harvester 
      Base base = (Base)minDist(myBases);
      float dist = distance(base);
      
      if(dist > explorerPerception / 2){
        goBackToBase();//while not in colation, stay near the base 
      } 
      
      else {
        
        if( brain[2].z == 3){
        //confirm coalition to both aquaintances and transmit confirm message 
        explorerConfirmCoalitionFormation(acquaintances[0], 2, 1); //send confirmation message to sendentary havester. It will reply and transmit his position.
        explorerConfirmCoalitionFormation(acquaintances[1], 2, 2); //same for nomad harvester 
        brain[2].z = 0; //recruitement is finished ! 
        brain[1].z = 2; //explorer belong to convey coalition now
        explorerSayHi(acquaintances[0]); //say hi to sedentary haverster. 
        explorerSayHi(acquaintances[1]); //say hi to nomad haverster. 
        System.out.println("YASSS, sendentary : " + acquaintances[0] + " | nomad : " + acquaintances[1]);
        } 
        
        else {
          Harvester harv1 = (Harvester)oneOf(perceiveRobots(friend, HARVESTER));
          Harvester harv2 = (Harvester)oneOf(perceiveRobots(friend, HARVESTER));
          
          if(brain[2].z == 0){
          //make proposition for both roles
          if(harv1 != null){
            explorerAskForJoiningCoalition(harv1, 2, 1); // job offer as sendentary havester
            acquaintances[0] = harv1.who; // we temporarly register th id of th harvester in order to wait for his answer. 
          }
          if(harv1 != null && harv2 != null && harv1.who != harv2.who){
            explorerAskForJoiningCoalition(harv2, 2, 2);
            acquaintances[1] = harv2.who; 
            }
          }
          else if(brain[2].z == 1){
            //make a prosition for second role if someone already accepted for the first one 
            if(harv1 != null && harv1.who != acquaintances[0]){ // checking that the new is not the one who accepted the other job
              explorerAskForJoiningCoalition(harv1, 2, 2); // we propose to the first havester to join the coalition as nomad harvester
              acquaintances[1] = harv1.who; 
            } else if (harv2 != null && harv2.who != acquaintances[0]){
              explorerAskForJoiningCoalition(harv2, 2, 2); // we propose to the second havester to join the coalition as nomad harvester
              acquaintances[1] = harv2.who;
            }
          }
          else if(brain[2].z == 2){
          // make a proposition for first role if someone already accepted the second
          if(harv1 != null && harv1.who != acquaintances[1]){ 
              explorerAskForJoiningCoalition(harv1, 2, 1); // we propose to the first havester to join the coalition as nomad harvester
              acquaintances[0] = harv1.who; 
            } else if (harv2 != null && harv2.who != acquaintances[1]){
              explorerAskForJoiningCoalition(harv2, 2, 1); // we propose to the second havester to join the coalition as nomad harvester
              acquaintances[0] = harv2.who;
            }
          }  
        }
      }
      
    }
    
    else //STANDALONE BEHAVIOR
    {
      
      ArrayList<Seed> seeds = perceiveSeeds(ennemy);
      if (brain[4].x == 1) {
        // go back to base...
        goBackToBase();
      }
      else if(seeds!=null){//Pietinement
        heading = towards(seeds.get(0))+random(-radians(20), radians(20));
        tryToMoveForward();
      }
      else {
        // ...or explore randomly
        randomMove(45);
      }
    }

    // tries to localize ennemy bases
    lookForEnnemyBase();
    // inform harvesters about food sources
    driveHarvesters();
    // inform rocket launchers about targets
    driveRocketLaunchers();

    // clear the message queue
    flushMessages();
  }

  //
  // LocateEnemy
  // ============
  // > try to localize an enemy target
  //
  void LocateEnemy() {
    // look for the closest ennemy robot
    Robot bob = ClassifyEnemy();
    if (bob != null) {
      // if one found, record the position and breed of the target
      brain[0].x = bob.pos.x;
      brain[0].y = bob.pos.y;
      brain[0].z = bob.breed;
      // locks the target
      brain[4].y = 1;
      //changes heading :
      heading = towards(brain[0]);
      //sends message to rockets
      //System.out.println("Explorer : target found, transmitting to rockets");
      TransmitTargetToTeam(bob);
    } else
      // no target found
      brain[4].y = 0;
      TransmitTargetToTeam(null);
  }
  
  //
  // ClassifyEnemy
  // =============
  // > function that will give the priority target
  // > priority functions like : 
  // harvesters > rockets > base > explorer
  //
  Robot ClassifyEnemy()
  {
    ArrayList<Robot> detectedEnemies = perceiveRobots(ennemy); //store all detected enemies
    HashMap<Integer, ArrayList<Integer>> enemyMap = new HashMap<Integer,ArrayList<Integer>>(); //we're storing all the accessible bots in a hashmap int,ArrayList<int> where the key indicates the priority (1 for harv, 4 for explor) and the arrayList all the robots of said priority
    enemyMap.put(1,new ArrayList<Integer>());
    enemyMap.put(2,new ArrayList<Integer>());
    enemyMap.put(3,new ArrayList<Integer>());
    enemyMap.put(4,new ArrayList<Integer>());
    if(detectedEnemies!=null)
    {
      for(int i=0;i<detectedEnemies.size();i++) //for each enemy type, we store them in the Hashmap
      {
        if(detectedEnemies.get(i).breed == HARVESTER)
        {
          ArrayList<Integer> locInt = enemyMap.get(1);
          locInt.add(i);
          enemyMap.put(1,locInt);
        }
        else if(detectedEnemies.get(i).breed == LAUNCHER)
        {
          ArrayList<Integer> locInt = enemyMap.get(2);
          locInt.add(i);
          enemyMap.put(2,locInt);
        }
        else if(detectedEnemies.get(i).breed == BASE)
        {
          ArrayList<Integer> locInt = enemyMap.get(3);
          locInt.add(i);
          enemyMap.put(3,locInt);
        }
        else
        {
          ArrayList<Integer> locInt = enemyMap.get(4);
          locInt.add(i);
          enemyMap.put(4,locInt);
        }
      }
      //now, we access the first min value found in the hashmap :
      if(enemyMap.get(1).size()!=0)
      {
        return detectedEnemies.get(enemyMap.get(1).get(0));
      }
      else if(enemyMap.get(2).size()!=0)
      {
         return detectedEnemies.get(enemyMap.get(2).get(0));     
      }
      else if(enemyMap.get(3).size()!=0)
      {
         return detectedEnemies.get(enemyMap.get(3).get(0));     
      }
      else if(enemyMap.get(4).size()!=0)
      {
         return detectedEnemies.get(enemyMap.get(4).get(0));     
      }
      else
      {
        return null;
      }
    }
    return null;
  }

  //
  // TransmitTargetToTeam
  // ====================
  // > transmit to every rocket in team the target selected by LocateEnemy()
  //
  void TransmitTargetToTeam(Robot target)
  {
    if(target!=null)
    {
      ArrayList<RocketLauncher> rockets = (ArrayList<RocketLauncher>)perceiveRobots(friend,LAUNCHER); //we detect all the present friendly rocket launchers
      if(rockets!=null){
        for(int i=0;i<rockets.size();i++)
        {
          if(rockets.get(i).who == acquaintances[3] || rockets.get(i).who == acquaintances[4]) //if the detected rocket is part of the team, send a message
          {
            informAboutTarget(rockets.get(i),target);
          }
        }
      }
    }
    else //if no target found, we tell the rockets that they have no target
    {
      ArrayList<RocketLauncher> rockets = (ArrayList<RocketLauncher>)perceiveRobots(friend,LAUNCHER); //we detect all the present friendly rocket launchers
      if(rockets!=null)
      {
        for(int i=0;i<rockets.size();i++)
        {
          if(rockets.get(i).who == acquaintances[3] || rockets.get(i).who == acquaintances[4]) //if the detected rocket is part of the team, tell them that they have no target
          {
            rockets.get(i).brain[4].y=0;
          }
        }
      }
    }
  }
  
  //
  // joinNomadHarvester
  // ============
  // > go found the nomad havester of the coalition until the explorer get enough food !
  //
  void joinNomadHarvester(){
      PVector position = new PVector();
      position.x = brain[1].x - 2;
      position.y = brain[1].y - 2; 
      heading = towards(position); 
      tryToMoveForward();
  }
  
  //
  // joinSedentaryHarvester
  // ============
  // > go found the sedentary havester of the coalition until the explorer get close enough to give it previously collected food
  //
  void joinSedentaryHarvester(){ 
      PVector position = new PVector();
      position.x = brain[2].x - 2;
      position.y = brain[2].y - 2; 
      heading = towards(position);  
      tryToMoveForward();
      
      //check id the sedentary is perceived and close enough
        ArrayList<Harvester> harvesters = (ArrayList<Harvester>)perceiveRobots(friend,HARVESTER); //check harvesters around.
        if(harvesters!=null){
          for(int i=0;i<harvesters.size();i++)
          {
            Harvester harvest = harvesters.get(i);
            if(harvest.who == acquaintances[0]){ //if we found the sedentary harvest, update its position 
              brain[2].x = harvest.pos.x;
              brain[2].y = harvest.pos.y;
              if(distance(harvest) <=2){
                giveFood(harvest, carryingFood); //and if close enough, give food; 
              }
              break;
            }
          }
        }
  }
  
  //
  // checkUponHarvesters
  // ============
  // > send Hello to other coalition Harvesters, in order to reset their coalition expiration timer and get a response to update their position in brain
  //
  void checkUponHarvesters(){
    explorerSayHi(acquaintances[0]);
    explorerSayHi(acquaintances[1]);
  }
  
  void tryToMoveTowardOrWait() {
    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }

  //
  // setTarget
  // =========
  // > locks a target
  //
  // inputs
  // ------
  // > p = the location of the target
  // > breed = the breed of the target
  //
  void setTarget(PVector p, int breed) {
    brain[0].x = p.x;
    brain[0].y = p.y;
    brain[0].z = breed;
    brain[4].y = 1;
  }

  //
  // goBackToBase
  // ============
  // > go back to the closest base, either to deposit food or to reload energy
  //
  void goBackToBase() {
    // bob is the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one (not all of my bases have been destroyed)
      float dist = distance(bob);

      if (dist <= 2) {
        // if I am next to the base
        if (energy < 500)
          // if my energy is low, I ask for some more
          askForEnergy(bob, 1500 - energy);
        // switch to the exploration state
        brain[4].x = 0;
        // make a half turn
        right(180);
      } else {
        // if still away from the base
        // head towards the base (with some variations)...
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward 
        tryToMoveForward();
      }
    }
  }

  //
  // target
  // ======
  // > checks if a target has been locked
  //
  // output
  // ------
  // true if target locket / false if not
  //
  boolean target() {
    return (brain[4].y == 1);
  }

  //
  // driveHarvesters
  // ===============
  // > tell harvesters if food is localized
  //
  void driveHarvesters() {
    // look for burgers
    Burger zorg = (Burger)oneOf(perceiveBurgers());
    if (zorg != null) {
      // if one is seen, look for a friend harvester
      Harvester harvey = (Harvester)oneOf(perceiveRobots(friend, HARVESTER));
      if (harvey != null)
        // if a harvester is seen, send a message to it with the position of food
        informAboutFood(harvey, zorg.pos);
    }
  }

  //
  // driveRocketLaunchers
  // ====================
  // > tell rocket launchers about potential targets
  //
  void driveRocketLaunchers() {
    // look for an ennemy robot 
    Robot bob = (Robot)oneOf(perceiveRobots(ennemy));
    if (bob != null) {
      // if one is seen, look for a friend rocket launcher
      RocketLauncher rocky = (RocketLauncher)oneOf(perceiveRobots(friend, LAUNCHER));
      if (rocky != null)
        // if a rocket launcher is seen, send a message with the localized ennemy robot
        informAboutTarget(rocky, bob);
    }
  }

  //
  // lookForEnnemyBase
  // =================
  // > try to localize ennemy bases...
  // > ...and to communicate about this to other friend explorers
  //
  void lookForEnnemyBase() {
    // look for an ennemy base
    Base babe = (Base)oneOf(perceiveRobots(ennemy, BASE));
    if (babe != null) {
      // if one is seen, look for a friend explorer
      Explorer explo = (Explorer)oneOf(perceiveRobots(friend, EXPLORER));
      if (explo != null)
        // if one is seen, send a message with the localized ennemy base
        informAboutTarget(explo, babe);
      // look for a friend base
      Base basy = (Base)oneOf(perceiveRobots(friend, BASE));
      if (basy != null)
        // if one is seen, send a message with the localized ennemy base
        informAboutTarget(basy, babe);
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
      right(random(360));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }
  
  void decreaseCoalitionTimer(){
    brain[3].y -= brain[3].z;
    if(brain[3].y <= 0){
      quitCoalition();
    }
  }
  
  void resetCoalitionTimer(){
    brain[3].y = brain[3].x;
  }
  
  void quitCoalition(){
    brain[1].z = 0;
    brain[2].z = 0; // reset coalition proporsal if not done yet 
    for(int i = 0; i<acquaintances.length ; i++){ //reset acquaintances and inform them about dissolving
      explorerDissolveCoalition(acquaintances[i]);
      acquaintances[i] = -1;
    }
    resetCoalitionTimer();
  }
  
  //
  // handleMessages
  // ==============
  // > handle messages received
  //
  void handleMessages() {
    PVector p = new PVector();
    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      // get next message
      msg = messages.get(i);
      
      if(msg.type == RESPOND_TO_COALITION_OFFER && msg.args[1] == colour){
          p.x = msg.args[0]; //response to the  offer ...
          
          if(p.x == 1){
            
            if(msg.alice == acquaintances[0]){ //.. from the potential sedentary 
              
              if(brain[2].z == 0){
                brain[2].z = 1; // the sedentary havester is the first to accept
              } else if (brain[2].z == 2){
                brain[2].z = 3; //the sedentary haverster is the second to accept
              }
              
            } else if (msg.alice == acquaintances[1]){ //... from the potentiel nomad
              
              if(brain[2].z == 0){
                brain[2].z = 2; // the nomad havester is the first to accept
              } else if (brain[2].z == 1){
                brain[2].z = 3; //the nomad haverster is the second to accept
              }
            
            }
            
          }
            
        }
      
      if(msg.type == HI_THERE && msg.args[2] == colour){
          p.x = msg.args[0]; //x coordinate of alice
          p.y = msg.args[1]; //y coordinate of alice 
          if(brain[4].z == 2){
            if(msg.alice == acquaintances[0]){ // if the one to say HI is the sedentary harvester :  
              resetCoalitionTimer();
              //update sedentary position : 
              brain[2].x = p.x;
              brain[2].y = p.y;
              } 
            if(msg.alice == acquaintances[1]){ // if the one to say HI is the nomad haverster
              resetCoalitionTimer();
              //update nomad position : 
              brain[1].x = p.x;
              brain[1].y = p.y;
            }
          }
            
        }
        
        if(msg.type == INFORM_ABOUT_DISSOLVING_COALITION && msg.args[0] == colour){
          quitCoalition();
        }
      
      
      if(brain[4].z != 2){ //the following messages do not concern the explorer of type "chief of convey coalition"
        // if "leader position update" message
        if (msg.type == 11 && msg.args[1]==colour) //tests if the message received is a position update demand from a rocket 
        {
          //System.out.println("Explorer : position update demand received");
          float[] arg = new float[3];
          arg[0]=pos.x;
          arg[1]=pos.y;
          arg[2]=colour;
          //System.out.println("Explorer : sending position update");
          sendMessage((int)msg.args[0],10,arg); //sending msg to rocket
        }
        else if (msg.type == 12 && msg.args[1]==colour) //tests if the message received is a link-up demand
        {
          //System.out.println("Explorer "+who+": link-up demand received");
          speed = launcherSpeed;
          brain[1].z = 1; //indicates that the explorer is part of the coalition formed by (this) rocket
          brain[1].x++;
          //we store in acquaintances 3 and 4 the id of the rockets of the coalition
          if(acquaintances[3]<0) 
          {
            acquaintances[3]=(int)msg.args[0];
          }
          else if(acquaintances[4]<0)
          {
            acquaintances[4]=(int)msg.args[0];
          }
        }
        
        else if (msg.type == 14 && msg.args[2] == colour)  //tests if the message received is a call for help
        {
           System.out.println("Explorer : Received call for help from " + msg.alice + " at " + msg.args[0] + ", " + msg.args[1]);
           brain[4].y = 1;
           brain[0].x = msg.args[0];
           brain[0].y = msg.args[1];
        }
        
        else if(msg.type == 15 && msg.args[1] == colour) //if the explorer receives a "disengage" message from one of its rocket launchers, it will remove it from its memory
        {
          //System.out.println("Explorer "+who+" : disengage message received");
          //we store in acquaintances 3 and 4 the id of the rockets of the coalition
          if(acquaintances[3]==msg.args[0]) 
          {
            acquaintances[3]=-1;
            brain[1].x--;
          }
          else if(acquaintances[4]==msg.args[0])
          {
            acquaintances[4]=-1;
            brain[1].x--;
          }
        }
        
        else if(msg.type == 180 && msg.args[1]==colour) //if the explorer receives a "request coalition informations" message from one rocket that requests the informations from the explorer
        {
          System.out.println("Explorer "+who+" : receiving request for coalition informations");
          float[] arg = new float[6];
          arg[0]=who;
          arg[1]=brain[1].x;
          arg[2]=brain[4].z;
          arg[3]=pos.x;
          arg[4]=pos.y;
          arg[5]=colour;
          sendMessage((int)msg.args[0], 181, arg); //sends the requested informations to the rocket
        }
        else if (msg.type == 140 && msg.args[1]==colour) //if the explorer receives a "request coalition type" message from a robot
        {
          System.out.println("Explorer "+who+" : receiving request for coalition informations");
          float[] arg = new float[2];
          arg[0]=brain[1].z; // coalition state
          arg[1]=colour; // colour of the sender
          sendMessage((int)msg.args[0], 141, arg); // returns the message with the information of type of the coalition
        }
      }
    }
    // clear the message queue
    flushMessages();
  }
  
  // ---------- COMMUNICATION SPECIFIC FUNCTIONS FOR RED_EXPLORER ------------//
  
  //Message used in order to suggest the creation of a new coalition to other robots, with this explorer as chief.
  void explorerAskForJoiningCoalition(Robot bob, int coalitionType, int role){
    // check that bob exists and distance is less than max range
    if ((bob != null) && (distance(bob) < messageRange)) {
      // build the message...
      float[] args = new float[3];
      args[0] = coalitionType;
      args[1] = role ;  
      args[2] = colour;
      sendMessage(bob.who, ASK_FOR_JOINING_COALITION, args);
    }
  }
  
  void explorerAskForJoiningCoalition(int id, int coalitionType, int role){
      // build the message...
      float[] args = new float[3];
      args[0] = coalitionType;
      args[1] = role ;
      args[2] = colour;
      sendMessage(id, ASK_FOR_JOINING_COALITION, args);
  }
  
  //Message used in order to confirm the creation of the coalition to other members.
  void explorerConfirmCoalitionFormation(Robot bob, int coalitionType, int finalRole){
    // check that bob exists and distance is less than max range
    if ((bob != null) && (distance(bob) < messageRange)) {
      // build the message...
      float[] args = new float[3];
      args[0] = coalitionType;
      args[1] = finalRole;  
      args[2] = colour;
      sendMessage(bob.who, CONFIRM_COALITION_FORMATION, args);
    }
  }
  
  void explorerConfirmCoalitionFormation(int id, int coalitionType, int finalRole){
      // build the message...
      float[] args = new float[3];
      args[0] = coalitionType;
      args[1] = finalRole;  
      args[2] = colour;
      sendMessage(id, CONFIRM_COALITION_FORMATION, args);
  }
  
  //Message used in order to inform other members about the end of the coalition .
  void explorerDissolveCoalition(Robot bob){
    // check that bob exists and distance is less than max range
    if ((bob != null) && (distance(bob) < messageRange)) {
      // build the message...
      float[] args = new float[1]; 
      args[0] = colour;
      sendMessage(bob.who, INFORM_ABOUT_DISSOLVING_COALITION, args);
    }
  }
  
   void explorerDissolveCoalition(int id){
      // build the message...
      float[] args = new float[1]; 
      args[0] = colour;
      sendMessage(id, INFORM_ABOUT_DISSOLVING_COALITION, args);
  }
  
  void explorerSayHi(Robot bob){
    // check that bob exists and distance is less than max range
    if ((bob != null) && (distance(bob) < messageRange)) {
      // build the message...
      float[] args = new float[3]; 
      args[0] = pos.x;
      args[1] = pos.y; 
      args[2] = colour;
      sendMessage(bob.who, HI_THERE, args);
    }
  }
  
  void explorerSayHi(int id){
      // build the message...
      float[] args = new float[3]; 
      args[0] = pos.x;
      args[1] = pos.y; 
      args[2] = colour;
      sendMessage(id, HI_THERE, args);
  }
   // ---------- END COMMUNICATION SPECIFIC FUNCTIONS FOR RED_EXPLORER ------------//
  
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the red harvesters
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   4.x = (0 = look for food | 1 = go back to base) 
//   4.y = (0 = no food found | 1 = food found)
//   4.z = harvester type (0 = basic | 1 = sendentary | 2 = nomad)

//   1.z = type of coalition (0 = None | 1 = convey coalition)

//   3.x = coalition expiration default duration;
//   3.y = current coalition timer ;
//   3.z = coalition delta time between each tick for the timer ;

//   0.x / 0.y = position of the localized food
//
// map of the aquaintances:
//   ??? if the harvester belongs to a convey colaition 
//     0 = id of the chief explorer
///////////////////////////////////////////////////////////////////////////
class RedHarvester extends Harvester {
  //
  // constructor
  // ===========
  //
  RedHarvester(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
    Base base = (Base)minDist(myBases);
    brain[4].x = base.pos.x;
    brain[4].y = base.pos.y;
    brain[3].x = 100;
    brain[3].y = 100;
    brain[3].z = 0.01;
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    // handle messages received
    handleMessages();
    
    // COALITION OR STANDALONE : Call for help
    Robot enemyLauncher = (Robot)minDist(perceiveRobots(ennemy, LAUNCHER));
    if (enemyLauncher != null) {
    // call for help
      System.out.println("Harvester " + who + " is calling for help at " + pos.x + ", " + pos.y); 
      float[] args = new float[2];
      args[0] = who;
      args[1] = colour;
      // for each explorer in range
      ArrayList<Robot> explorers = perceiveRobots(friend, EXPLORER);  
      if (explorers != null) {
        for (int i = 0; i < explorers.size(); i++) {
          // ask the type of their coalition (0 no coalition, 1 attack coalition, 2 harvest coalition)
             sendMessage(explorers.get(i).who, 140, args);
        }
      }
    }
    
    //COALITION OR STANDALONE : Search for burger
    Burger b = (Burger)minDist(perceiveBurgers());
    if ((b != null) && (distance(b) <= 2))
      // if one is found next to the robot, collect it
      takeFood(b);

    // if food to deposit (when your not a nomad harvester) or too few energy
    if (( brain[4].z != 2 && (carryingFood > 200)) || (energy < 100))
      // time to go back to the base
      brain[4].x = 1;

    // if in "go back" state
    if (brain[4].x == 1) {
      // go back to the base
      goBackToBase();

      // if enough energy and food
      if ((energy > 100) && (carryingFood > 100)) {
        // check for closest base
        Base bob = (Base)minDist(myBases);
        if (bob != null) {
          // if there is one and the harvester is in the sphere of perception of the base
          if (distance(bob) < basePerception)
            // plant one burger as a seed to produce new ones
            plantSeed();
        }
      }
    }
    else if (brain[1].z == 1) { //CONVEY COALITION BEHAVIOR 
    
      Base base = (Base)minDist(myBases);
      float dist = distance(base);
    
      if (brain[4].z == 1) { // sendentary behavior
      
        if(dist > basePerception){
          brain[4].x = 1; //if the sedentary haverster got too far, it's going back to base
        } else {
          goAndEat();
        }
        
      }
      
      
      else if (brain[4].z == 2){ // nomad behavior 
      
        //check if the chief explorer (convey coalition) is close enough to give it food
        ArrayList<Explorer> explorers = (ArrayList<Explorer>)perceiveRobots(friend,EXPLORER); //check the explorers around.
        if(explorers!=null){
          for(int i=0;i<explorers.size();i++)
          {
            Explorer explo = explorers.get(i);
            if(explo.who == acquaintances[0]){ //if we founf the chief of the coalition
              giveFood(explo, carryingFood);
              harvesterSayHi(explo);
              break;
            }
          }
        }
        
        
        if(dist < basePerception * 2){ //if we are too close from the base, we go away;
          heading = towards(base) + random(-radians(20), radians(20));
          right(180);
          tryToMoveForward();
        } 
        else { //if the harvester is far enough, explore as usual;
          goAndEat();
        }
        
      }
      decreaseCoalitionTimer();
    }
    else { // BASIC BEHAVIOR
    
      /*Base base = (Base)minDist(myBases);
          if (base != null) {
            // if there is one
            if (distance(base) > basePerception + harvesterPerception) {
              brain[4].x = 1;
            }
          }*/
      // if not in the "go back" state, explore and collect food
      goAndEat();
    }
  }

  //
  // goBackToBase
  // ============
  // > go back to the closest friend base
  //
  void goBackToBase() {
    // look for the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one
      float dist = distance(bob);
      if ((dist > basePerception) && (dist < basePerception + 1))
        // if at the limit of perception of the base, drops a wall (if it carries some)
        dropWall();

      if (dist <= 2) {
        // if next to the base, gives the food to the base
        giveFood(bob, carryingFood);
        if (energy < 500)
          // ask for energy if it lacks some
          askForEnergy(bob, 1500 - energy);
        // go back to "explore and collect" mode
        brain[4].x = 0;
        // make a half turn
        right(180);
      } else {
        // if still away from the base
        // head towards the base (with some variations)...
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward();
      }
    }
  }

  //
  // goAndEat
  // ========
  // > go explore and collect food
  //
  void goAndEat() {
    // look for the closest wall
    Wall wally = (Wall)minDist(perceiveWalls());
    // look for the closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      float dist = distance(bob);
      // if wall seen and not at the limit of perception of the base 
      if ((wally != null) && ((dist < basePerception - 1) || (dist > basePerception + 2)))
        // tries to collect the wall
        takeWall(wally);
    }

    // look for the closest burger
    Burger zorg = (Burger)minDist(perceiveBurgers());
    if (zorg != null) {
      // if there is one
      if (distance(zorg) <= 2)
        // if next to it, collect it
        takeFood(zorg);
      else {
        // if away from the burger, head towards it...
        heading = towards(zorg) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward();
      }
    } else if (brain[4].y == 1) {
      // if no burger seen but food localized (thank's to a message received)
      if (distance(brain[0]) > 2) {
        // head towards localized food...
        heading = towards(brain[0]);
        // ...and try to move forward
        tryToMoveForward();
      } else
        // if the food is reached, clear the corresponding flag
        brain[4].y = 0;
    } else {
      // if no food seen and no food localized, explore randomly
      heading += random(-radians(45), radians(45));
      tryToMoveForward();
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
      right(random(360));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }
  

  //
  // handleMessages
  // ==============
  // > handle messages received
  // > identify the closest localized burger
  //
  void handleMessages() {
    float d = width;
    PVector p = new PVector();

    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      // get next message
      msg = messages.get(i);
      
      // if "localized food" message
      if (msg.type == INFORM_ABOUT_FOOD) {
        // record the position of the burger
        p.x = msg.args[0];
        p.y = msg.args[1];
        if (distance(p) < d) {
          // if burger closer than closest burger
          // record the position in the brain
          brain[0].x = p.x;
          brain[0].y = p.y;
          // update the distance of the closest burger
          d = distance(p);
          // update the corresponding flag
          brain[4].y = 1;
        }
      } else if (msg.type == 141 && msg.args[1] == colour) {
        // if the explorer is in an attack coalition send message to order defense
          if (msg.args[0] == 1) {
            float[] arg = new float[3];
            arg[0] = pos.x;  // position of the sender
            arg[1] = pos.y;  // position of the sender
            arg[2] = colour;  // colour of the sender
            sendMessage(msg.alice, 14, arg); // harvester sends a message to the attack coalition to ask them to come help 
          }
      }
      
        if(msg.type == ASK_FOR_JOINING_COALITION && msg.args[2] == colour){
          p.x = msg.args[0]; //type of coalition 
          p.y = msg.args[1]; //job offer 
          if(brain[1].z == 0){ // if not in a coalition 
            if(p.x == 2){ //proporsal of convey colaition
              if((p.y == 2 && energy > harvesterNrj*3/4) // we accept nomad offer only if we do have at least 75%
                  || (p.y == 1) ){ // we always accept sedentary offers 
                harvesterRespondToCoalitionOffer(msg.alice, true);
              } else { //if the offer doesn't correspon to anything known, decline. 
                harvesterRespondToCoalitionOffer(msg.alice, false);
              }
              
             }
          }
        }
        
        if(msg.type == CONFIRM_COALITION_FORMATION && msg.args[2] == colour){
          p.x = msg.args[0]; //type of coalition 
          p.y = msg.args[1]; //final job attribution  
          if(p.x == 2){ //convey coalition case 
            brain[1].z = 1; // register the coalition 
            brain[4].z = p.y; //register its new responsibilities (sendentary or nomad)
            acquaintances[0] = msg.alice; //register the id of the chief explorer 
            harvesterSayHi(acquaintances[0]); //say hi to chief in order to transmit initial position 
            } 
        }
        
        if(msg.type == HI_THERE && msg.args[2] == colour){
          p.x = msg.args[0]; //x coordinate of alice
          p.y = msg.args[1]; //y coordinate of alice 
          if(msg.alice == acquaintances[0]){ // if the one to say HI is the coalition chief : 
            // TODO : reset coalition expiration timer 
            resetCoalitionTimer();
            harvesterSayHi(msg.alice); //say hi back to the chief. 
            } 
        }
        
        if(msg.type == INFORM_ABOUT_DISSOLVING_COALITION && msg.args[0] == colour){
          quitCoalition();
        }
        
      }
      
    // clear the message queue
    flushMessages();
  }
  
  void decreaseCoalitionTimer(){
    brain[3].y -= brain[3].z;
    if(brain[3].y <= 0){
      quitCoalition();
    }
  }
  
  void resetCoalitionTimer(){
    brain[3].y = brain[3].x;
  }
  
  void quitCoalition(){
    brain[1].z = 0;
    brain[4].z = 0;
    for(int i = 0; i<acquaintances.length ; i++){
      acquaintances[i] = -1;
      resetCoalitionTimer();
    }
  }
  
   // ---------- COMMUNICATION SPECIFIC FUNCTIONS FOR RED_HARVESTER------------//
  
  //Message used in order to confirm or not the participation oh the harvester to the coalition.
  void harvesterRespondToCoalitionOffer(Robot bob, boolean accepted){
    // check that bob exists and distance is less than max range
    if ((bob != null) && (distance(bob) < messageRange)) {
      // build the message...
      float[] args = new float[2];
      args[0] = accepted ? 1 : 0; 
      args[1] = colour;
      sendMessage(bob.who, RESPOND_TO_COALITION_OFFER, args);
    }
  }
  
  void harvesterRespondToCoalitionOffer(int id, boolean accepted){
      // build the message...
      float[] args = new float[2];
      args[0] = accepted ? 1 : 0; 
      args[1] = colour;
      sendMessage(id, RESPOND_TO_COALITION_OFFER, args);
  }
  
  
  //Message used in order to inform about the end of the coalition 
  void harvesterDissolveCoalition(Robot bob){
    // check that bob exists and distance is less than max range
    if ((bob != null) && (distance(bob) < messageRange)) {
      // build the message...
      float[] args = new float[1]; 
      args[0] = colour;
      sendMessage(bob.who, INFORM_ABOUT_DISSOLVING_COALITION, args);
    }
  }
  
   void harvesterDissolveCoalition(int id){
      // build the message...
      float[] args = new float[1]; 
      args[0] = colour;
      sendMessage(id, INFORM_ABOUT_DISSOLVING_COALITION, args);
  }
  
  void harvesterSayHi(Robot bob){
    // check that bob exists and distance is less than max range
    if ((bob != null) && (distance(bob) < messageRange)) {
      // build the message...
      float[] args = new float[3]; 
      args[0] = pos.x;
      args[1] = pos.y; 
      args[2] = colour;
      sendMessage(bob.who, HI_THERE, args);
    }
  }
  
  void harvesterSayHi(int id){
      // build the message...
      float[] args = new float[3]; 
      args[0] = pos.x;
      args[1] = pos.y;
      args[2] = colour;
      sendMessage(id, HI_THERE, args);
  }
   // ---------- END OF COMMUNICATION SPECIFIC FUNCTIONS FOR RED_HARVESTER ------------//
   
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the red rocket launchers
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   0.x / 0.y = position of the target
//   0.z = breed of the target
//   1.z = if in squad (0 if no, 1 if yes)
//   1.x / 1.y = position of leader
//   2.x = if leader is alive (0 if no, 1 if yes)
//   4.x = (0 = look for target | 1 = go back to base) 
//   4.y = (0 = no target | 1 = localized target)
//   5.x / 5.y = position of the base that created it
///////////////////////////////////////////////////////////////////////////
class RedRocketLauncher extends RocketLauncher {
  //
  // constructor
  // ===========
  //
  RedRocketLauncher(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
  void go() {
    // if no energy or no bullets
    if ((energy < 100) || (bullets == 0))
      // go back to the base
      brain[4].x = 1;
    
    if(brain[1].z==1) //SQUAD BEHAVIOR
    {
      if(energy<100) //if the rocket is lacking energy and will soon die, it disengages from the explorer
      {
        //System.out.println("Rocket "+who+" : disengaging");
        float[] arg = new float[2];
        arg[0]=who;
        arg[1]=colour;
        sendMessage(acquaintances[1], 15, arg);
        //we clean up the rocket's memory :
        acquaintances[1]=-1;
        brain[1].x = 0;
        brain[1].y = 0;
        brain[1].z = 0;
        return;
      }
      UpdateExplorer(); //updates position with explorer's
      // handle messages received
      handleMessages();
      if(brain[4].y==1) //if a target's been found by the leader, the rocket attacks it
      {
        //since the target is given by explorer, we'll make it so the rockets try to go towards the target to enter effective range
        tryToMoveTowardLeader();
        launchBullet(towards(brain[0]));
      }
      else //if no target given by explorer, rockets look for one themselves
      {
        FollowLeader(); //the rocket will attempt to follow leader IF they don't have a target
        selectTarget(); //after following leader, it tries to find a suitable target -> Later, this should be changed as the explorer finding a target
        if(target())
        {
          launchBullet(towards(brain[0]));
        }
      }
    }
    else //STANDARD ALONE BEHAVIOR
    {
      // handle messages received
      handleMessages();
      if(FindExplorer())//when alone, a rocket will try to find an explorer to link to
      {
        return; //if a leader's been found, we avoid doing the standard alone behavior
      }
      
      Base base = (Base)minDist(myBases);
      if (distance(base) > basePerception + explorerPerception) {
        // if too far from base go back to it and defend it
        brain[4].x = 1;
      } else {
        // try to find a target
        selectTarget();
        // if target identified
        if (target())
        {
          // shoot on the target
          launchBullet(towards(brain[0]));
        }
        else
        {
          // else explore randomly
          randomMove(45);
        }
      }      
      
      if (brain[4].x == 1) 
      {
        // if in "go back to base" mode
        goBackToBase();
      } 
    }
  }

  //
  // selectTarget
  // ============
  // > try to localize a target
  //
  void selectTarget() {
    // look for the closest ennemy robot
    Robot bob = (Robot)minDist(perceiveRobots(ennemy));
    if (bob != null) {
      // if one found, record the position and breed of the target
      brain[0].x = bob.pos.x;
      brain[0].y = bob.pos.y;
      brain[0].z = bob.breed;
      // locks the target
      brain[4].y = 1;
    } else
      // no target found
      brain[4].y = 0;
  }

  //
  // target
  // ======
  // > checks if a target has been locked
  //
  // output
  // ------
  // > true if target locket / false if not
  //
  boolean target() {
    return (brain[4].y == 1);
  }

  //
  // goBackToBase
  // ============
  // > go back to the closest base
  //
  void goBackToBase() {
    // look for closest base
    Base bob = (Base)minDist(myBases);
    if (bob != null) {
      // if there is one, compute its distance
      float dist = distance(bob);

      if (dist <= 2) {
        // if next to the base
        if (energy < 500)
          // if energy low, ask for some energy
          askForEnergy(bob, 1500 - energy);
        // go back to "exploration" mode
        brain[4].x = 0;
        // make a half turn
        right(180);
      } else {
        // if not next to the base, head towards it... 
        heading = towards(bob) + random(-radians(20), radians(20));
        // ...and try to move forward
        tryToMoveForward();
      }
    }
  }

  //
  // tryToMoveForward
  // ================
  // > try to move forward after having checked that no obstacle is in front
  //
  void tryToMoveForward() {
    // if there is an obstacle ahead, rotate randomly
    if (!freeAhead(speed))
      right(random(360));

    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }
  
  //
  // tryToMoveTowardLeader
  // ================
  // > try to move towards the leader after having checked that no obstacle is in front - if something is in front, it will just remain here
  //
  void tryToMoveTowardLeader() {
    // if there is no obstacle ahead, move forward at full speed
    if (freeAhead(speed))
      forward(speed);
  }
  
  //
  //  FollowLeader
  //  ============
  //  > try to follow leader
  //
  void FollowLeader(){
    if(brain[1]!=null)
    {
       brain[1].x-=3; //small offset, might be removed
       brain[1].y-=3;
       heading = towards(brain[1]);
    }
    tryToMoveTowardLeader();
  }
  
  //
  //  FindExplorer
  //  ============
  //  > try to find suitable leader (returns true if leader found)
  //
  boolean FindExplorer()
  {
    // try to find a suitable coalition leader :
      Explorer explorer = (Explorer)oneOf(perceiveRobots(friend,EXPLORER));
      if(explorer!=null) //if an explorer is found, we request from it informations that will tell the rocket wether or not a coalition can be formed
      {
        //System.out.println("Rocket "+who+" : sending link message request to explorer "+explorer.who);

        float[] arg = new float[2];
        arg[0]=who;
        arg[1]=colour;
        System.out.println("Rocket "+who+" : sending request for coalition information from the explorer");
        sendMessage(explorer.who, 180, arg); //we try to send a message to an explorer in the vicinity to obtain informations
        return true;
      }
      return false;
  }
  
  //
  //  UpdateExplorer
  //  ============
  //  > calls for leader's position update
  //
  void UpdateExplorer(){
    //MESSAGE VERSION :
    if(acquaintances[1]>0) //if the rocket has a team leader (explorer) we demand its position
    {
      float[] arg = new float[2];
      arg[0]=who;
      arg[1]=colour;
      sendMessage(acquaintances[1],11,arg); //request position update
    }
  }
  
  //
  // handleMessages
  // ==============
  // > handle messages received
  // > identify the closest localized burger
  //
  void handleMessages() {
    Message msg;
    // for all messages
    for (int i=0; i<messages.size(); i++) {
      // get next message
      msg = messages.get(i);
      // if "localized target" message
      if (msg.type == INFORM_ABOUT_TARGET) {
        //System.out.println("Rocket Launcher : Target information received");
        // record the position of the target
        brain[0].x = msg.args[0];
        brain[0].y = msg.args[1];
        brain[0].z = msg.args[2];
        brain[4].x=0;
        brain[4].y=1;
        //change heading to target :
        heading = towards(brain[0]);
      }
      else if(msg.type == 10 && msg.args[2]==colour) //r??ception message d'update de position du leader
      {
        brain[1].x = msg.args[0];
        brain[1].y = msg.args[1];
      }
      else if(msg.type==13 && msg.args[1]==colour) //reception of dissolution message
      {
        //System.out.println("Rocket "+who+" : received dissolution message from Explorer "+msg.args[0]);
        brain[1].z=0;
        acquaintances[1]=-1;
      }
      else if(msg.type == 181 && msg.args[5]==colour) //reception of explorer coalition informations
      {
        System.out.println("Rocket "+who+" : received coalition informations from Explorer "+msg.args[0]);
        if(msg.args[1]<2 && msg.args[2]!=1) //if the received information is valid, we form a coalition 
        {
          System.out.println("Rocket "+who+" : sending link message request to explorer "+msg.args[0]);
          float[] arg = new float[2];
          arg[0]=who;
          arg[1]=colour;
          acquaintances[1]=(int)msg.args[0];//we save in the acquaintances the id of the explorer
          brain[1].x = msg.args[3];
          brain[1].y = msg.args[4];
          brain[1].z = 1;
          sendMessage((int)msg.args[0], 12, arg); //send a link-up request message is sent to the explorer
        }
      }
    }
    // clear the message queue
    flushMessages();
  }
}
