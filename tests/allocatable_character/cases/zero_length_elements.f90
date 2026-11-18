program main
implicit none
character(:),allocatable::a(:,:)
allocate(character(-3)::a(-1:0,4:5))
a='x'
print *,allocated(a),len(a),size(a),a(0,4)=='',len(a(:,4))

end program
