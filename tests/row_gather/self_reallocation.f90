program p
implicit none
integer,allocatable::a(:,:)
allocate(a(3,2))
a=reshape([1,2,3,4,5,6],[3,2])
a=a([3,1],:)
print *,shape(a),a
end program
