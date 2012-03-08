plotModel <- function(model, cnolist=NULL, bString=NULL, indexInteger=NA, signals=NULL, stimuli=NULL, inhibitors=NULL,
    ncno=NULL, compressed=NULL, output="STDOUT", filename=NULL,graphvizParams=list()){
#  "$Id: plotModel.R 380 2011-12-19 16:42:58Z cokelaer $"

# Quick example:
# ---------------
#   filename = "ToyPKNMMB.sif"
#   g = plotModel(model, cnolist=cnolist)
#   # g$graph contains the model transformed into a graph object

# For optimal rendering, required a hacked version of renderGraph.R from
# Rgraphviz (v1.32).


    # Some required library to build the graph and plot the results using
    # graphviz.
    library(Rgraphviz)
    library(RBGL)

    # Set the output filename
    if (is.null(filename)){
        filename="model"
        output_dot = "model.dot"
    }
    else{
        output_dot = paste(filename, ".dot", sep="")
    }

    # Set the image format if any
    if (output %in% c("STDOUT", "PDF", "PNG", "SVG") != TRUE){ 
        stop("wrong outputformat.Must be in PDF, PNG, SVG")
    }
    else{
       if (output=="PDF"){ 
            pdf(paste(filename, ".pdf", sep=""))
        }
       else if (output=="PNG"){
            png(paste(filename, ".png", sep=""))
        }
       else if (output=="SVG"){ 
            svg(paste(filename, ".svg", sep=""), pointsize=22, width=10, height=10)
        }
    }

    # Input data. If the cnolist is a character, we guess that the user provided the MIDAS
    # filename from which we can try to construct the cnolist.  
    if (typeof(cnolist) == "character"){
        tryCatch({cnolist = makeCNOlist(readMIDAS(cnolist, verbose=FALSE), subfield=FALSE)},
            error=function(e){stop("An error occured while trying to create the cnolist.
            Invalid MIDAS file provided maybe?")})
    }

    # Input data. If the model is a character, we guess that the user provided
    # the MODEL filename (sif format) that we can read.
    if (typeof(model) == "character"){
        raw = read.table(model)  # read the PKN data
        # build the unique vertices from the column 1 and 3 of the SIF file
        vertices = unique(c(as.character(raw$V1), as.character(raw$V3)))
        v1 = raw$V1 # alias to vertices in column 1
        v2 = raw$V3 # alias to vertices in column 2
        edges = raw$V2 # alias to the edges
        BStimes<-rep(1,length(edges)) # the bitstring to color the edges
        Integr<-rep(0,length(edges))  # 
    }
    # otherwise, the user probably provided the model already read by readSif
    # in which case, and gates must be extracted from strings such as
    # "node1+node2=node3"
    # This block is the tricky part of the function. Change with care.
    else if (typeof(model)=="list" && any("namesSpecies" == names(model))){ 
        # namesSpecies == names(model) try to check if model resemble the output of readSif ?
        # ideally we should have a type.

        # build the unique vertices from the nameSpecies
        vertices = model$namesSpecies

        # now, we need to split the reaction to get back the different edges
        mysplit = function(x){strsplit(x, "=")}
        reacs = mysplit(model$reacID) # separate the reactions into left and right parts
        tmp <- unlist(mysplit(model$reacID))
        reacs = t(matrix(unlist(mysplit(model$reacID)), ncol=length(tmp)/2)) # reordering

        # Use the bString and indexInteger input arguments to build up 
        if (is.null(bString)){# default is only 1 so all edges are accepted
            optimBStimes<-rep(1,dim(reacs)[1])
        }else{
            optimBStimes<-bString
        }

        optIntegr<-rep(0,length(optimBStimes))
        if (!is.na(indexInteger[1])){
            optIntegr[indexInteger]<-1
        }

        # finally, build the v1, v2 and edges
        BStimes<-vector()
        Integr<-vector()

        CountReac<-1
        CountAnds<-1
        mysplit2 = function(x){strsplit(x, "+", fixed=TRUE)}
        v1<-vector()
        v2<-vector()
        edges<-vector()
        for (i in 1:dim(reacs)[1]){
          inputs<-unlist(strsplit(reacs[i,1],"+", fixed=TRUE))
          if (length(inputs)==1){
            v1[CountReac] = reacs[i,1]
            edges[CountReac] = 1
            v2[CountReac] = reacs[i,2]
            if (length(grep("!", v1))){
                v1[CountReac] = sub("!", "", v1[CountReac])
                edges[CountReac] = -1
            }
            BStimes[CountReac]<-optimBStimes[i]
            Integr[CountReac]<-optIntegr[i]
            CountReac<-CountReac+1
          }else{
            for (j in 1:length(inputs)){
              v1[CountReac]<-inputs[j]
              edges[CountReac] = 1
              v2[CountReac]<-paste("and",CountAnds,sep="")
              if (length(grep("!", v1[CountReac]))){
                v1[CountReac] = sub("!", "", v1[CountReac])
                edges[CountReac] = -1
              }
              BStimes[CountReac]<-optimBStimes[i]
              Integr[CountReac]<-optIntegr[i]
              CountReac<-CountReac+1
            }
            v1[CountReac]<-paste("and",CountAnds,sep="")
            edges[CountReac] = 1
            v2[CountReac] = reacs[i,2]
            BStimes[CountReac]<-optimBStimes[i]
            Integr[CountReac]<-optIntegr[i]
            CountReac<-CountReac+1
            vertices<-c(vertices,paste("and",CountAnds,sep=""))
            CountAnds<-CountAnds+1
          }
        }
    }

    if (is.null(cnolist) == FALSE){ # if a cnolist is provided, fill
                                    # signals/stimulis/inhitors
        stimuli <- cnolist$namesStimuli
        signals <- cnolist$namesSignals
        inhibitors <- cnolist$namesInhibitors
        #inhibitors <- cnolist$namesInhibitors
    }

    # build the edges. IGraph does not use names for the vertices but ids 
    # that starts at zero. Let us build a data.frame to store the correspondence
    # between the ids and names.
    l = length(vertices) - 1

    # build the graph 
    g <- new("graphNEL", nodes=vertices, edgemode="directed")
    weights = rep(1, l) # for now, the weights are to 1.
    for (i in 1:length(v1)){
        g <- addEdge(as.character(v1[i]), as.character(v2[i]), g, weights[i])
    }

    # The graph is now built. We can proceed with node and edge attributes for
    # the output files 

    recipEdges="distinct" # an edge A->B does not overlap with B->A

    # --------------------------------------- Build the node and edges attributes list
    nodeAttrs = createNodeAttrs(g, vertices, stimuli, signals, inhibitors, ncno, compressed)
    res = createEdgeAttrs(v1, v2, edges, BStimes, Integr)

    # createEdge returns the edgeAttrs and a list of edges that correspond to a
    # bistring element that is zero. In such case, the edge is useless and can
    # be removed. 
    toremove = res$toremove
    for (x in toremove){
        y = unlist(strsplit(x, "~"))
        g = removeEdge(y[1], y[2], g)
    }
    # Some nodes are now connected to no other nodes. These nodes can be
    # removed. In principle, this is only and nodes.  
    orphans = nodes(g)[(degree(g)$inDegree  + degree(g)$outDegree) ==0]
    for (x in orphans){
        g = removeNode(x, g)
    }

    edgeAttrs = res$edgeAttrs
    # --------------------------- the ranks computation for the layout
    clusters = create_layout(g, signals, stimuli)

    # ------------------------------ general attributes
    # for some obscure reasons, must set style="filled" right her even though it
    # is then overwritten by nodesAttrs$style later on otherwise the output.dot
    # does not contain any style option

    # dot uses this value but the Rgraphviz plot arrowsize is done
    # automatically.
    arrowsize=2
    fontsize=22
    size="10,10"
    # size does not work in Rgraphviz version 1.32 wait and see for new version.
    attrs <-
        list(node=list(fontsize=fontsize,fontname="Helvetica",style="filled,bold"),
             edge=list(style="solid", penwidth=1,weight="1.0",arrowsize=arrowsize),
             graph=list(splines=TRUE,size=size,bgcolor="white",ratio="fill",pad="0.5,0.5",dpi=72 ))
    # other options
    # in graph: pad="0.5,5"))
    # in graph, add a title with main="Model"))

    # ------------------ plotting
    #clusters = NULL
    if (is.null(clusters)){
        plot(g,"dot",attrs=attrs,nodeAttrs=nodeAttrs,edgeAttrs=edgeAttrs,recipEdges=recipEdges)
        toDot(g, output_dot, nodeAttrs=nodeAttrs,edgeAttrs=edgeAttrs,attrs=attrs, recipEdges=recipEdges)
        #system(paste("dot -Tsvg ",output_dot," -o temp.svg; mirage temp.svg", sep=""))
    }
    else{
        copyg <- g
#        plot(g,"dot",attrs=attrs,nodeAttrs=nodeAttrs,edgeAttrs=edgeAttrs,subGList=clusters,recipEdges=recipEdges)

        nodeRenderInfo(g) <- list(
            fill=nodeAttrs$fillcolor, 
            col=nodeAttrs$color,
            style=nodeAttrs$style,
#            lty=nodeAttrs$lty,   # does not work with Rgraphviz 1.32 can be used with patched version
            lwd=2,             # width of the nodes. IF provided, all nodes have the same width
            label=nodeAttrs$label,
            shape=nodeAttrs$shape,
            cex=0.4,

            fontsize=fontsize,
            iwidth=nodeAttrs$width,
            iheight=nodeAttrs$height,
            fixedsize=FALSE)

       # the arrowhead "normal" is buggy in Rgraphviz version 1.32 so switch to
       # "open" for now. However, the dot output keeps using the normal arrow. 
       arrowhead2 = edgeAttrs$arrowhead
       arrowhead2[arrowhead2=="normal"] = "open"

       # once Rgraphviz is updated, one should be able to uncomment col and lwd
       # which are buggy for the moment.
#edgeRenderInfo(g) <- list(
#can be used with Rgraphviz patch:          col=edgeAttrs$color,
#           arrowhead=arrowhead2,
           #head=v2,
            #tail=v1,
#            label=edgeAttrs$label,
#           lwd=2,
#can be used with Rgraphviz patch:           lwd=edgeAttrs$penwidth,
#            lty="solid"
#        )

        # graphRenderInfo is not used. Uses attrs instead.
        # graphRenderInfo(g) <-  list()

        # finally, the layout for a R plot
        x <- layoutGraph(g,layoutType="dot",subGList=clusters,recipEdges=recipEdges,attrs=attrs)
        renderGraph(x)
        # and save into dot file.
        toDot(copyg,output_dot,nodeAttrs=nodeAttrs,edgeAttrs=edgeAttrs,subGList=clusters,attrs=attrs,recipEdges=recipEdges)
#        try(system(paste("dot -Tsvg ",output_dot,"  -o temp.svg; mirage temp.svg", sep="")))
    }
    if (output != "STDOUT"){dev.off()}
    return(list(graph=g, attrs=attrs, nodeAttrs=nodeAttrs, edgeAttrs=edgeAttrs,clusters=clusters, v1=v1, v2=v2, edges=edges))
}


# if a cnolist, or at least signals/stimuli, then we can create ranking for the
# layout 
create_layout <- function(g, signals, stimuli){

    # this algo will tell us the distance between vertices
    # distMatrix columns contains the distance from a vertex to the others
    distMatrix <- floyd.warshall.all.pairs.sp(g)
    distMatrix[is.infinite(distMatrix) == TRUE] <- -Inf # convert Inf to be able
                         

    # if signals provided by the user is empty, let us find ourself the nodes
    # with input degrees set to zero:
    if (is.null(stimuli)==TRUE){
        stimuli = nodes(g)[degree(g)$inDegree==0]
    }

    # we will need to know the sinks
    sinks  <- signals[degree(g, signals)$outDegree == 0]

    # compute max rank for each column
    ranks <- apply(distMatrix, 2, max)
    mrank = max(ranks, na.rm=TRUE)-1  # -1 because we already know the sinks

    clusters <- list()
    if (mrank >= 1){ # otherwise, nothing to do. 
        # for each different rank select the names of the column to create a
        # cluster
        for (rank in 1:mrank){  # starts at 1 although ranks starts at 0.
                                # However, 0 corresponds to the source that are
                                # known already
            # nodes found for a particular rank may contain a sink, that should
            # be removed
            nodes2keep = NULL
            nodes <- names(ranks[which(ranks==rank)])
            for (n in nodes){
                if (any(n==sinks) == FALSE){ nodes2keep <- c(nodes2keep, n)}
            }

            # may fail sometimes
            tryCatch({
                thisCluster <- subGraph(nodes2keep, g)
                thisGraph <-list(graph=thisCluster,cluster=FALSE,attrs=c(rank="same"))
                clusters[[length(clusters)+1]] =  thisGraph},
             error=function(e){"warning: clustering in the layout failed. carry on..."})

        }
    }
    # first the stimulis
    tryCatch(
        {
            clusterSource <- subGraph(stimuli, g)
            clusterSource<-list(graph=clusterSource,cluster=FALSE,attrs=c(rank="source"))
        },
        error=function(e){}
    )

    # then the signals keeping only those with outDegree==0
    tryCatch(
        {
            clusterSink <- subGraph(signals[degree(g, signals)$outDegree == 0], g)
            clusterSink <- list(graph=clusterSink, cluster=FALSE,
            attrs=c(rank="sink"))
        }, error=function(e){}
    )

    tryCatch(
        {clusters[[length(clusters)+1]] = clusterSource},
         error=function(e){}
    )
    tryCatch(
        {clusters[[length(clusters)+1]] = clusterSink}, 
        error=function(e){}
    )

    return(clusters)
}


# Create the node attributes and save in a list to be used either by the
# plot function of the nodeRenderInfo function.
createNodeAttrs <- function(g, vertices, stimuli, signals, inhibitors, ncno, compressed){

    # ----------------------------------------------- Build the node attributes list
    fillcolor <- list()
    color <- list()
    style <- list()  # the style of what is inside the node. 
    lty <- list()    #style of the contour node
    height <-list()
    label <- list()
    width <- list()
    fixedsize <- list()
    shape <- list()

    # default. Must be filled in case no signals/stimulis/cnolist are provided
    # Default node attributes
    for (s in vertices){
        color[s] <- "black"         # color edge
        fillcolor[s] <- "white"     # fill color
        style[s] <- "filled, bold"  
        lty[s] <- "solid"           
        label[s] <- s
        height[s] <- 1
        width[s] <- 2
        fixedsize[s] <- FALSE
        shape[s] <- "ellipse" 
    }

    # The stimulis node
    for (s in stimuli){ 
        fillcolor[s] <- "olivedrab3"; 
        color[s] <- "olivedrab3";
        style[s] <- "filled"
    }
    # The signal nodes
    for (s in signals){ #must be before the inhibitors to allow bicolors
        fillcolor[s] <- "lightblue"; 
        color[s] <-"lightblue";
    }
    # The inhibitor node, that may also belong to the signal category.
    for (s in inhibitors){
        if (length(grep(s, signals))>=1){
            fillcolor[s] <- "SkyBlue2"
            style[s] <- "filled,bold,diagonals"
            color[s] <-"orangered"
        }
        else{
            fillcolor[s] <- "orangered"; 
            color[s] <-"orangered";
        }
    }
    # The compressed nodes
    for (s in compressed){ 
        fillcolor[s] <- "white"; 
        color[s] <- "black"; 
        style[s] <- "dashed,bold"; 
        lty[s]="dashed";
    }
    # The NCNO node
    for (s in ncno){ 
        fillcolor[s] <- "white"; 
        color[s] <- "grey"; 
        fillcolor[s] = "grey"
    }
    # the and gate nodes
    for (s in vertices){
        if (length(grep("and", s))>=1){
            color[s] = "black"
            fillcolor[s] = "black"
            width[s]=0.1
            height[s]=0.1
            fixedsize[s]=FALSE
            shape[s]="circle"
            label[s] = ""
        }
    }
    nodeAttrs <- list(fillcolor=fillcolor, color=color, label=label, width=width, height=height,
        style=style, lty=lty, fixedsize=fixedsize, shape=shape)

    return(nodeAttrs)
}


# Create the node attributes and save in a list to be used either by the
# plot function of the edgeRenderInfo function.
createEdgeAttrs <- function(v1, v2, edges, BStimes ,Integer){


    edgewidth_c = 4 # default edge width

    # The edge attributes
    arrowhead <- list()
    edgecolor <- list()
    edgewidth <- list()
    label <- list()
    toremove <- list()
    for (i in 1:length(edges)){
        edgename = paste(v1[i], "~", v2[i], sep="")
        edgewidth[edgename] = edgewidth_c    # default edgewidth
        label[edgename] = ""                 # no label on the edge by default

        if (edges[i] == 1){
           arrowhead[edgename] <- "normal"
           edgecolor[edgename] <- "forestgreen"
        }
        else if (edges[i] == -1){
           arrowhead[edgename] <- "tee"
           edgecolor[edgename] <- "red"
        }
        else{
           arrowhead[edgename] <- "normal"
           edgecolor[edgename] <- "blue"
        }

        # BStimes contains the bistring. color the edges according to its value 
        v = (BStimes[i]*100)%/%1
        #print(c(BStimes[i], v))
        if (v != 100){
            if (v == 0){
                if (length(grep("and", edgename))>=1){
                    toremove <- append(toremove, edgename)
                }
                edgecolor[edgename] = "transparent"
            }
            else{
              edgecolor[edgename] <- paste("grey", as.character(100-v), sep="")
              edgewidth[edgename]  = edgewidth_c*(v/100)
              label[edgename] = as.character(v)
            }
        }
    }

    indexI<-intersect(which(Integer==1), which(BStimes==1))
    edgecolor[indexI]<-"purple"

    edgeAttrs <- list(color=edgecolor,arrowhead=arrowhead, penwidth=edgewidth,label=label)
	return(list(toremove=toremove, edgeAttrs=edgeAttrs))
}
