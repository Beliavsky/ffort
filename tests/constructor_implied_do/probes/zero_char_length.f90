program main
implicit none
integer::i
character(2)::a(0)
a=[("ab",i=2,1)]
print *,size(a),len(a)
end program
