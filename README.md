
# PROJECT 3:  IMPLEMENTATION OF TAPESTRY  ALGORITHM

### COP5615 - Distributed Operating Systems Principles

The goal of the project was to implement the Tapestry Peer to Peer Overlay Network to allow network join and key-based prefix routing in a distributed environment.  
The project consisits of 2 parts:  
Part 1 in the folder "Project3" covers the implementation of the Tapestry network.  
Part 2 in the folder "Project3bonus" covers the implementation along with fault tolerance and handling failures of several nodes.  

### Date: October 25, 2019

## Team Members:
1.	Karan Manghani (UFID: 7986-9199) Email: karanmanghani@ufl.edu
2.	Yaswanth Bellam (UFID: 2461-6390) Email: yaswanthbellam@ufl.edu

## Steps to run the code: 
1.	Clone/Download the file
2.	Using CMD/ terminal, go the directory where you have downloaded the zip file
3.	Type  ‘cd Gossip-and-Push-Sum-Algorithm-master' (to enter the project directory)
4.	Run the command “mix run project3.exs arguments”
5.	Note: Type the arguments based on the implementation given below.

## Input Format for Part-1: 
```sh
mix run project3.exs numnodes numrequests 
```

## Input Format for Part-2: 
```sh
mix run project3.exs numnodes numrequests numnodesfailed
```

## Implementation: 

Each process maintains a routing table which stores references (hash values in our project) for a subset of the process in the system and it is defined by 2 parameters:
1.	Level 
2.	Slot  
Each level signifies the number of characters that matched for a given process in the system with the process whose routing table we are creating. Hence, based on the number of bits of the hash value, the number of levels is set.  If we use an 8-bit hash, we have 8 levels (ranging from level 0 through 7 in our project, where level 0 signifies no matches and level 7 signifies all but the last bit is the same) This method is also known as prefix-matching.   The slot signifies the column where the process would reside.  
Example: Consider we are creating a routing table for process 12ab.  
If we encounter a process, with hash 0f01, since prefix-match = 0, the process will reside at level 0 and slot 0 (the character of the process where match failed)  
If we encounter another process, with the hash 1234, the process would reside at level 2, since “12” match, and slot 3.  
Since, we could have multiple options for a given entry in the routing table, we select the one that is closest to the hash of the root process.  
Improvements for fault-tolerance:  
Here, to improve robustness and avoid failure, we store multiple references in each slot. Here, we are storing 3 references that are sorted in the order of closeness to the local node.   
![nodes-image](/screenshots/2c62.PNG)
Thus, in our program, if a process crashes, and we were supposed to find another process via this crashed process, then we find another route, by selecting the second one. If the second one also crashes, we go for the third one.

![rerouting](/screenshots/rerouting.PNG)

If the destination, i.e. requested node has crashed, then we return the message,

<br/>
![dest](/screenshots/dest.PNG)

<br/>
Since the requesting process might not know if its request process has crashed, then doesn’t. Thus, if a request was made to the node that has crashed, we store the number of hops in the requesting processes’ state as “-1”.    Then, based on future availability, if the node revives, the number of hops would easily be reset and we could get the true value of number of hops.  
The below image for the routing table of hash 6706 explains the idea:  
a.	The first part is the routing table of the node 6706  
b.	The second list is the random requests for the node 6706.  
c.	The third list stores the number of hops it took for each request.   
d.	Finally, we output the max number of hops for 6706. 
<br/> 
![25fc](/screenshots/25fc.PNG)

<br/>
Since destination 25FC wasn’t available, the processes’ state stores -1 for 25FC.  


## Maximum number of nodes tested for the above implementation:
Nodes: 8000  
Requests: 3  
![max](/screenshots/maximum .PNG)
