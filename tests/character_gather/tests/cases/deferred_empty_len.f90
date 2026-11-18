implicit none
character(:),allocatable::x(:)
integer::idx(0)
allocate(character(4)::x(0))
print *,size(x(idx)),len(x(idx))
end
