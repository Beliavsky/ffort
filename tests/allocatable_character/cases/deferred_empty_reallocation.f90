program main
implicit none
character(:),allocatable::a(:)
a=[character(6)::]
print *,allocated(a),len(a),size(a),lbound(a,1),ubound(a,1)
a=[character(2)::]
print *,allocated(a),len(a),size(a)

end program
