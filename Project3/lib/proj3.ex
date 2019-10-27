defmodule Project do
  use GenServer
  
  def start(data) do
    numnodes = Enum.at(data, 0)
    n = numnodes-1
    numrequests = Enum.at(data, 1)
    Registry.start_link(name: :my_registry, keys: :unique)
    hdigits = 8
    Enum.map(1..n, fn x ->
      pid = startnodes([%{}, [], List.duplicate(0, numrequests)])
      {:ok, _} = Registry.register(:my_registry, pid , :crypto.hash(:sha256, "#{x}") |> Base.encode16 |> String.slice(0, hdigits))
    end)
    plist = Registry.select(:my_registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    hlist = Registry.select(:my_registry, [{{:_, :_, :"$2"}, [], [:"$2"]}])
    #IO.inspect plist
    process_map =
    Enum.reduce(0..length(hlist) - 1, %{}, fn z, acc ->
      Map.put(acc, Enum.at(hlist, z), Enum.at(plist, z))
    end)
    createrouting(hlist, process_map)
    
    #NETWORK JOIN
    joinpid = startnodes([%{}, [], List.duplicate(0, numrequests)])
    #plist = plist ++ [joinpid]
    joinhash =  :crypto.hash(:sha256, "#{numnodes}") |> Base.encode16 |> String.slice(0, hdigits)
    hlist = hlist ++ [joinhash]
    #IO.inspect hlist
    process_map = Map.put(process_map, joinhash, joinpid)
    networkjoin(hlist, process_map)
    redotables(hlist, process_map)
    insertneighbors(hlist, process_map, numrequests)
    routeit(hlist, process_map)
    maxhop = Enum.reduce(hlist, [], fn x, acc ->
      # l0 = Enum.at(statechecker(process_map, x), 0)
      # l1 = Enum.at(statechecker(process_map, x), 1)
      l2 = Enum.at(statechecker(process_map, x), 2)
      # IO.inspect l0 #Prints the routing table
      # IO.inspect l1 #Prints the requests for each process 
      # IO.inspect l2 #Prints the max hops per process
      _acc = acc ++ [Enum.max(l2)]
   end)
       IO.inspect Enum.max(maxhop)
  end

  def statechecker(process_map,hashval) do
      GenServer.call(get_pid(process_map, hashval), {:statechecker})
  end
  
  def handle_call({:statechecker}, _from, state) do
    {:reply, state, state}
  end

  def routeit(hlist, process_map) do
    Enum.each(hlist, fn x ->
      GenServer.cast(get_pid(process_map, x), {:hopper, x, process_map})
    end)
  end
  
  def createrouting(hlist,process_map) do
    Enum.each(hlist, fn x ->
      tablemaker(hlist, x, process_map)
    end)
  end

  def networkjoin(hlist, process_map) do
    x = Enum.at(hlist, length(hlist)-1)
    tablemaker(hlist, x, process_map)
  end

  def redotables(hlist, process_map) do
    joinhash = Enum.at(hlist, length(hlist)-1)
    Enum.each(List.delete(hlist, joinhash), fn x ->
      GenServer.cast(get_pid(process_map, x), {:updatetable, x, joinhash})
    end)
  end

  def insertneighbors(hlist, process_map, num) do
    Enum.each(hlist, fn x ->
      randomneighbors = Enum.take_random(List.delete(hlist, x), num)
      GenServer.cast(get_pid(process_map, x), {:randomrequestlist, randomneighbors})
  end)
  end

  def tablemaker(hlist, x, process_map) do
    map =
      Enum.reduce(List.delete(hlist, x), %{}, fn y, acc ->
        count = checknoofsimilardigits(x, y)
        pos = String.slice(y, 0, count + 1) |> String.last()
        innermap = Map.get(acc, count)
        if(innermap == nil) do
          Map.put(acc, count, %{pos => y})
        else
          oldhash = Map.get(innermap, pos)
          if(oldhash == nil) do
            a = Map.put(innermap, pos, y)
            Map.put(acc, count, a)
          else
            if(dist(x, y) < dist(x, oldhash)) do
              a = Map.put(innermap, pos, y)
              Map.put(acc, count, a)
            else
              a = Map.put(innermap, pos, oldhash)
              Map.put(acc, count, a)
            end
          end
        end
      end)
      
      map =
      Enum.reduce(0..String.length(x) - 1, map, fn row, acc ->
        pos = String.at(x, row)
        innermap = Map.get(acc, row)
        if(innermap == nil) do
          Map.put(acc, row, %{pos => x})
        else
          innermap = Map.put(innermap, pos, x)
          Map.put(acc, row, innermap)
        end
      end)
      GenServer.cast(get_pid(process_map, x), {:createtable, map, []})
  end

  def dist(h1, h2) do
    {h1dec, ""} = Integer.parse(h1, 16)
    {h2dec, ""} = Integer.parse(h2, 16)
    abs(h1dec - h2dec)
  end
  
  def checknoofsimilardigits(str1,str2) do
    count = 0
    y = Enum.map(1..String.length(str1), fn x-> 
      _count = cond do
        String.slice(str1, 0, x) == String.slice(str2, 0, x) ->
          _count = x
        true ->
          count
        end
    end)
    c = Enum.max(y)
    if(c == String.length(str1)) do
      c - 1
    else
      c
    end
  end

  def handle_cast({:createtable, routingtable, neighborlist}, state) do
    [_table, _nl, hops] = state
    state = [routingtable, neighborlist,hops]
    #IO.inspect state
    {:noreply, state}
  end

  def handle_cast({:randomrequestlist, neighborlist}, state) do
    [table, _nl, hops] = state
    state = [table, neighborlist, hops]
    #IO.inspect state
    {:noreply, state}
  end

  def handle_cast({:updatetable, currenthash, newhash}, state) do
    [map, nl, hops] = state
    x = currenthash
    map =
      Enum.reduce([newhash], map, fn y, acc ->
        count = checknoofsimilardigits(x, y)
        pos = String.slice(y, 0, count + 1) |> String.last()
        innermap = Map.get(acc, count)
        if(innermap == nil) do
          Map.put(acc, count, %{pos => y})
        else
          oldhash = Map.get(innermap, pos)
          if(oldhash == nil) do
            a = Map.put(innermap, pos, y)
            Map.put(acc, count, a)
          else
            if(dist(x, y) < dist(x, oldhash)) do
              a = Map.put(innermap, pos, y)
              Map.put(acc, count, a)
            else
              a = Map.put(innermap, pos, oldhash)
              Map.put(acc, count, a)
            end
          end
        end
      end)
      state = [map,nl,hops]
     # IO.inspect state
    {:noreply, state}
  end

  def handle_cast({:updatehops, index}, state) do
    #IO.inspect state
    [table, nl, hops] = state
    updatedhops = List.update_at(hops, index, &(&1 + 1))
    state = [table, nl, updatedhops]
   # IO.puts state
    {:noreply, state}
  end

  def handle_cast(:statechecker, state) do
     
     IO.inspect state
     {:noreply, state}
  end
  
  def handle_cast({:hopper, current, process_map}, state) do
    [_map, neighbors, _hops] = state
    Enum.each(0..length(neighbors)-1, fn i ->
      neigh = Enum.at(neighbors, i)
      #IO.inspect "Searching for #{neigh}"
      GenServer.cast(self(), {:counthops, current, neigh, process_map, current, i})
    end)
    {:noreply, state}
  end

  def handle_cast({:counthops, current, neigh, process_map, main, index}, state) do
    [map, _neighbors, _hops] = state
    row = checknoofsimilardigits(current, neigh)
    innermap = Map.get(map, row)
    pos = String.slice(neigh, 0, row + 1) |> String.last()
    hashatloc = Map.get(innermap, pos)
  #   IO.inspect "Found #{hashatloc}. was looking for #{neigh}"
    _numhops =
    if(hashatloc == neigh) do
      0
     # IO.inspect "WE FOUND #{neigh} for #{current}"
    else
      #IO.inspect "INCREMENTING HOPS"
      #IO.inspect "Looking in #{hashatloc}'s table"
      GenServer.cast(get_pid(process_map, main), {:updatehops, index})
      current = hashatloc
      GenServer.cast(get_pid(process_map, current), {:counthops, current, neigh, process_map, main, index})
    end
    {:noreply, state}
  end

  def get_pid(process_map,hash) do
    Map.get(process_map, hash)
  end

  def startnodes(state) do
    {:ok, pid} = GenServer.start_link(__MODULE__, state)
    pid
  end

  def init(state) do
    {:ok, state}
  end
end