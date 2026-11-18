program p
implicit none
character(:),allocatable::a(:),b(:)
integer::i,undefined
allocate(character(5)::a(0))
allocate(character(5)::b(0))
forall(i=1:size(a)) a(i)=achar(undefined)
b=a
print *,allocated(a),allocated(b),len(a),len(b),size(a),size(b)
end program
