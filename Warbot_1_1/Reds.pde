///////////////////////////////////////////////////////////////////////////
//
// The code for the red team
// ===========================
//
///////////////////////////////////////////////////////////////////////////

class RedTeam extends Team {
  final int MY_CUSTOM_MSG = 5;
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
    // creates a new harvester
    newHarvester();
    // 7 more harvesters to create
    brain[5].x = 7;
    brain[5].z = 2;
  }
  
  void chooseNewRobot(){
    // creates new robots depending on energy and the state of brain[5]
    if ((brain[5].x > 0) && (energy >= 1000 + harvesterCost)) {
      // 1st priority = creates harvesters 
      if (newHarvester())
        brain[5].x--;
    } else if ((brain[5].y > 0) && (energy >= 1000 + launcherCost)) {
      // 2nd priority = creates rocket launchers 
      if (newRocketLauncher())
        brain[5].y--;
    } else if ((brain[5].z > 0) && (energy >= 1000 + explorerCost)) {
      // 3rd priority = creates explorers 
      if (newExplorer())
        brain[5].z--;
    } 
    //No priority : random
    else if (energy > 12000) {
      ArrayList seeds = perceiveSeeds(friend);
      ArrayList robots = perceiveRobots(friend, HARVESTER);

      if(seeds!=null && robots!=null)
          if(seeds.size()>150 && robots.size()>4) //lot of harvest
            brain[5].y++;
          else if(seeds.size()<50)
            brain[5].x++;        
      // if no robot in the pipe and enough energy 
      else if ((int)random(2) == 0)
        // creates a new harvester with 50% chance
        brain[5].x++;
      else if ((int)random(2) == 0)
        // creates a new rocket launcher with 25% chance
        brain[5].y++;
      else
        // creates a new explorer with 25% chance
        brain[5].z++;
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
    Robot bob = (Robot)minDist(perceiveRobots(ennemy, LAUNCHER));
    if (bob != null) {
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
//   0.x / 0.y = coordinates of the target
//   0.z = type of the target
//   1.x = number of rockets in the coalition (2 max)
//   1.z = if in a coalition
///////////////////////////////////////////////////////////////////////////
class RedExplorer extends Explorer {
  //
  // constructor
  // ===========
  //
  RedExplorer(PVector pos, color c, ArrayList b, Team t) {
    super(pos, c, b, t);
  }

  //
  // setup
  // =====
  // > called at the creation of the agent
  //
  void setup() {
    brain[1].x=0;
  }

  //
  // go
  // ==
  // > called at each iteration of the game
  // > defines the behavior of the agent
  //
void go() {
    //if die
    if(energy<50){
        Base bob = (Base)minDist(myBases);
        if (bob != null) 
            bob.brain[5].z+=1;      
    }
  handleMessages();
    // if food to deposit or too few energy
    if ((carryingFood > 200) || (energy < 100))
      // time to go back to base
      brain[4].x = 1;

    // depending on the state of the robot
    if(brain[1].z==1) //COALITION BEHAVIOR
    {
      LocateEnemy();
      if(energy < 100){
        brain[4].x = 1;}
      //In coalition, the explorer will attempt to locate enemies, by classing them in priority, and then transmit that target to the team's rocket launchers
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
    else //STANDALONE BEHAVIOR
    {
      if (brain[4].x == 1) {
        // go back to base...
        goBackToBase();
      } else {
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
      ArrayList<RocketLauncher> rockets = (ArrayList<RocketLauncher>)perceiveRobots(friend,LAUNCHER); //RIGHT NOW, we assume that all rockets in vicinity are part of the team -> should include a way to either directly communicate, or see if they are indeed part of the team
      if(rockets!=null){
        for(int i=0;i<rockets.size();i++)
        {
          //System.out.println("Explorer : sending msg to rocket "+rockets.get(i));
          informAboutTarget(rockets.get(i),target);
          //rockets.get(i).brain[2].z=1;
        }
      }
    }
    else //if no target found, we tell the rockets that they have no target
    {
      ArrayList<RocketLauncher> rockets = (ArrayList<RocketLauncher>)perceiveRobots(friend,LAUNCHER); //RIGHT NOW, we assume that all rockets in vicinity are part of the team -> should include a way to either directly communicate, or see if they are indeed part of the team
      if(rockets!=null)
      {
        for(int i=0;i<rockets.size();i++)
        {
          //informAboutTarget(rockets.get(i),null);
          rockets.get(i).brain[4].y=0;
        }
      }
    }
    
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
      // if "leader position update" message
      if (msg.type == 11) //tests if the message received is a position update demand from a rocket 
      {
        System.out.println("Explorer : position update demand received");
        float[] arg = new float[2];
        arg[0]=pos.x;
        arg[1]=pos.y;
        System.out.println("Explorer : sending position update");
        sendMessage((int)msg.args[0],10,arg); //sending msg to rocket
      }
      else if(msg.type == 12) //tests if the message received is a link-up demand
      {
        System.out.println("Explorer : link-up demand received");
        speed = launcherSpeed;
        brain[1].z = 1; //indicates that the explorer is part of the coalition formed by (this) rocket
        brain[1].x++;
      }
    }
    // clear the message queue
    flushMessages();
  }
}

///////////////////////////////////////////////////////////////////////////
//
// The code for the red harvesters
//
///////////////////////////////////////////////////////////////////////////
// map of the brain:
//   4.x = (0 = look for food | 1 = go back to base) 
//   4.y = (0 = no food found | 1 = food found)
//   0.x / 0.y = position of the localized food
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
    if(energy<50){
        Base bob = (Base)minDist(myBases);
        if (bob != null) 
            bob.brain[5].x+=1;      
    }
    
    // check for the closest burger
    Burger b = (Burger)minDist(perceiveBurgers());
    if ((b != null) && (distance(b) <= 2))
      // if one is found next to the robot, collect it
      takeFood(b);
    
    if (brain[1].z == 0) {
      // Harvester is out of the coalition
      
      Base base = (Base)minDist(myBases);
      if (base != null) {
      // if there is one
      if (distance(base) > basePerception + harvesterPerception) {
        brain[4].x = 1;
      }
        
        // if food to deposit or too few energy
      if ((carryingFood > 200) || (energy < 100))
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
      } else
        // if not in the "go back" state, explore and collect food
        goAndEat();
      }
    } else if (brain[1].z == 1) {
      // Harvester is in a the coalition
      
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
      }
    }
    // clear the message queue
    flushMessages();
  }
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
    if(energy<50){
        Base bob = (Base)minDist(myBases);
        if (bob != null) 
            bob.brain[5].y+=1;      
    }
    // if no energy or no bullets
    if ((energy < 100) || (bullets == 0))
      // go back to the base
      brain[4].x = 1;

    if (brain[4].x == 1) 
    {
      // if in "go back to base" mode
      goBackToBase();
    } 
    else if(brain[1].z==1) //SQUAD BEHAVIOR
    {
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
      if(FindExplorer())//when alone, a rocket will try to find an explorer to link to
      {
        return; //if a leader's been found, we avoid doing the standard alone behavior
      }
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
      if(explorer!=null && explorer.brain[1].x<2) //right now, we only test if explorer exists && has less than 2 ppl in squad
      {
        System.out.println("Rocket : sending link message request to explorer "+explorer.who);
        float[] arg = new float[1];
        arg[0]=who;
        acquaintances[1]=explorer.who; //we save in the acquaintances the id of the explorer
        brain[1].x = explorer.pos.x;
        brain[1].y = explorer.pos.y;
        brain[1].z = 1;
        sendMessage(explorer.who, 12, arg); //send a link-up request message is sent to the explorer
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
      float[] arg = new float[1];
      arg[0]=who;
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
      else if(msg.type == 10) //réception message d'update de position du leader
      {
        brain[1].x = msg.args[0];
        brain[1].y = msg.args[1];
      }
      
    }
    // clear the message queue
    flushMessages();
  }
}
