implicit none
character(7),allocatable::x(:)
integer::idx(2)
print *,len(x(idx)),kind(x(idx))
end
