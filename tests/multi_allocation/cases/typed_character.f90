program p
implicit none
character(:),allocatable::a(:),b(:,:)
integer::n=3,s
allocate(character(len=n)::a(2),b(-1:0,2),stat=s)
a="xy"
b="abcde"
print *,s,len(a),len(b),all(a=="xy "),all(b=="abc"),size(b)
deallocate(a,b,stat=s)
print *,s,allocated(a),allocated(b)
end program
