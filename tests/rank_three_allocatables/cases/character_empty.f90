program p
character(:),allocatable::a(:,:,:),b(:,:,:)
allocate(character(3)::a(2,3,0)); a='abc'
b=a
print *,allocated(a),len(a),size(a),size(a,1),size(a,2),size(a,3)
print *,allocated(b),len(b),size(b),size(b,1),size(b,2),size(b,3)
end program
