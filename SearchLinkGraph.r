SearchLinkGraph <-
function(node1,node2,graph,noNodes=vector()){
  # looks in the graph if there is a connection between node1 and node2
  # giving as output 1 if they are connected and 0 otherwise
  
  #detete from the graph the nodes through which we cannot pass
  if (length(noNodes>0)){
    noNodes<-intersect(noNodes,nodes(graph))
    gg<-removeNode(noNodes,graph)
  }else{
	  gg<-graph
  }
  
  nod<-nodes(gg)
  edg<-edges(gg)
  
  if (any(which(nod==node1))){
    queue<-edg[[which(nod==node1)]]
	gg<-removeNode(node1,gg)
	nod<-nodes(gg)
	edg<-edges(gg)
  }else{
    queue<-vector()
  }
  
  ck<-0
  while (length(queue)>0 && ck!=1){
	if (any(which(nod==queue[1]))){
      queue<-c(queue, edg[[which(nod==queue[1])]])
	}
    if(any(queue==node2)){
      ck<-1
    }
	if (any(which(nod==queue[1]))){
	  gg<-removeNode(queue[1],gg)
	  nod<-nodes(gg)
	  edg<-edges(gg)
	}
	queue<-queue[-1]
  }
  return(ck)
}