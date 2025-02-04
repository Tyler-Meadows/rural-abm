##Matrices
function get_adjacency_matrix(model)
    if model.model_steps == 0
        @warn "Retrieving adjacency matrix before model has stepped (i.e. empty matrix)."
    end
    A = DataFrame(Agent = Int64[], Contact = Int64[], Count = Float64[])
    for agent in allagents(model)
        for i in findall(!iszero,agent.contact_list)
            push!(A,[agent.id i agent.contact_list[i]])
        end
    end
    for agent in eachrow(model.DeadAgents)
        for i in findall(!iszero,agent.contact_list)
            push!(A,[agent.Agent, i, agent.contact_list[i]])
        end
    end
    return sparse(A.Agent, A.Contact, A.Count)
end

function get_compact_adjacency_matrix(model)
    AdjacencyMatrix = get_adjacency_matrix(model)

    # Convert information into a vector with entry one equivalent to the size of the adjacency matrix
    # Note: CompactAdjacencyMatrix includes diagonal
    CompactAdjacencyMatrix = Vector{Int64}()
    nAgents = AdjacencyMatrix.m
    append!(CompactAdjacencyMatrix,nAgents)
    for row in 1:nAgents
        for col in row:nAgents
            append!(CompactAdjacencyMatrix, round(Int,AdjacencyMatrix[row,col]))
        end
    end

    return CompactAdjacencyMatrix
end

function decompact_adjacency_matrix(filename)
    # Import the vector
    contact_matrix_vector = CSV.read(filename, DataFrame, header=false)

    # First entry is the width/height of the matrix
    width = contact_matrix_vector[1,1]

    # Initialize matrix with zeros
    contact_matrix = zeros(width,width)

    # Construct Contact Matrix
    vector_iterator = 2
    for row in 1:width
        for col in row:width
            value = contact_matrix_vector[vector_iterator,1]
            contact_matrix[row,col] = value
            contact_matrix[col,row] = value
            vector_iterator += 1
        end
    end

    return contact_matrix
end

function household_adjacency(model)
    A = DataFrame(Agent = Int64[], Contact = Int64[], Household = Int64[], Contact_household= Int64[], Count = Float64[])
    for agent in allagents(model)
        for i in findall(!iszero, agent.contact_list)
            try
            push!(A,[agent.id i agent.home model[i].home agent.contact_list[i]])
            catch
            push!(A,[agent.id, i, agent.home,
                    filter(x->x.Agent==i,model.DeadAgents).Home[1],
                    agent.contact_list[i]])
            end
        end
    end
    select!(A,[:Household, :Contact_household, :Count])
    A =  combine(groupby(A, [:Household, :Contact_household]), :Count => sum => :Count)
    return sparse(A.Household, A.Contact_household, A.Count)
end

function household_size(model)
    A = DataFrame(Agent = Int64[], Household = Int64[], Counter = Bool[])
    for agent in allagents(model)
            A = push!(A,[agent.id agent.home true])
    end
    A = combine(groupby(A, :Household),:Counter => count => :Number)
    sort!(A,:Household)
    return A
end
