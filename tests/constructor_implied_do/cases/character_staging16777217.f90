program main
implicit none
integer::i
character(97)::x
character(97),allocatable::a(:)
x="x"
print '(a)',"before"
a=[(x,i=1,172961)]
print *,size(a),len(a)
end program
