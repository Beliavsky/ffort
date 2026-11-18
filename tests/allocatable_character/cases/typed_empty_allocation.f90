program main
implicit none
character(:),allocatable::a(:,:)
allocate(character(6)::a(1:0,1:2))
print *,allocated(a),len(a),size(a)

end program
