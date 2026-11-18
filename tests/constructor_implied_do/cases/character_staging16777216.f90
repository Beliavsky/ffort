program main
implicit none
integer::i
character(4096)::x
character(4096),allocatable::a(:)
x="x"
print '(a)',"before"
a=[(x,i=1,4096)]
print *,size(a),len(a)
end program
