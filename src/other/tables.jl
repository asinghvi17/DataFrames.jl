Tables.istable(::Type{<:AbstractDataFrame}) = true
Tables.columnaccess(::Type{<:AbstractDataFrame}) = true
Tables.columns(df::AbstractDataFrame) = df
Tables.rowaccess(::Type{<:AbstractDataFrame}) = true
Tables.rows(df::AbstractDataFrame) = eachrow(df)

Tables.schema(df::AbstractDataFrame) = Tables.Schema(names(df), eltype.(eachcol(df)))
Tables.materializer(df::AbstractDataFrame) = DataFrame

Tables.getcolumn(df::AbstractDataFrame, i::Int) = df[!, i]
Tables.getcolumn(df::AbstractDataFrame, nm::Symbol) = df[!, nm]
Tables.columnnames(df::AbstractDataFrame) = names(df)

Tables.getcolumn(dfr::DataFrameRow, i::Int) = dfr[i]
Tables.getcolumn(dfr::DataFrameRow, nm::Symbol) = dfr[nm]
Tables.columnnames(dfr::DataFrameRow) = names(dfr)

getvector(x::AbstractVector) = x
getvector(x) = [x[i] for i = 1:length(x)]
# note that copycols is ignored in this definition (Tables.CopiedColumns implies copies have already been made)
fromcolumns(x::Tables.CopiedColumns, names; copycols::Bool=true) =
    DataFrame(AbstractVector[getvector(Tables.getcolumn(x, nm)) for nm in names],
              Index(collect(Symbol, names)),
              copycols=false)
fromcolumns(x, names; copycols::Bool=true) =
    DataFrame(AbstractVector[getvector(Tables.getcolumn(x, nm)) for nm in names],
              Index(collect(Symbol, names)),
              copycols=copycols)

function DataFrame(x::T; copycols::Bool=true) where {T}
    if x isa AbstractVector && all(col -> isa(col, AbstractVector), x)
        return DataFrame(Vector{AbstractVector}(x), copycols=copycols)
    end
    if x isa AbstractVector || x isa Tuple
        if all(v -> v isa Pair{Symbol, <:AbstractVector}, x)
            return DataFrame(AbstractVector[last(v) for v in x], [first(v) for v in x],
                             copycols=copycols)
        end
    end
    cols = Tables.columns(x)
    return fromcolumns(cols, Tables.columnnames(cols), copycols=copycols)
end

function Base.append!(df::DataFrame, table; cols::Symbol=:setequal)
    if table isa Dict && cols == :orderequal
        throw(ArgumentError("passing `Dict` as `table` when `cols` is equal to " *
                            "`:orderequal` is not allowed as it is unordered"))
    end
    append!(df, DataFrame(table, copycols=false), cols=cols)
end

# This supports the Tables.RowTable type; needed to avoid ambiguities w/ another constructor
DataFrame(x::AbstractVector{<:NamedTuple}; copycols::Bool=true) =
    fromcolumns(Tables.columns(Tables.IteratorWrapper(x)), copycols=false)
DataFrame!(x::AbstractVector{<:NamedTuple}) =
    throw(ArgumentError("It is not possible to construct a `DataFrame` from " *
                        "`$(typeof(x))` without allocating new columns: use " *
                        "`DataFrame(x)` instead"))

Tables.istable(::Type{<:Union{DataFrameRows,DataFrameColumns}}) = true
Tables.columnaccess(::Type{<:Union{DataFrameRows,DataFrameColumns}}) = true
Tables.rowaccess(::Type{<:Union{DataFrameRows,DataFrameColumns}}) = true
Tables.columns(itr::Union{DataFrameRows,DataFrameColumns}) = Tables.columns(parent(itr))
Tables.rows(itr::Union{DataFrameRows,DataFrameColumns}) = Tables.rows(parent(itr))
Tables.schema(itr::Union{DataFrameRows,DataFrameColumns}) = Tables.schema(parent(itr))
Tables.materializer(itr::Union{DataFrameRows,DataFrameColumns}) =
    Tables.materializer(parent(itr))

IteratorInterfaceExtensions.getiterator(df::AbstractDataFrame) = Tables.datavaluerows(columntable(df))
IteratorInterfaceExtensions.isiterable(x::AbstractDataFrame) = true
TableTraits.isiterabletable(x::AbstractDataFrame) = true
