program main
implicit none
character(2)::x(4)
integer(8)::idx(4)
x=['AA','BB','CC','DD']
idx=iand(shiftr([12_8,10_8,12_8,14_8],1),maskr(2,kind=8))+1
print '(4(a2,1x))',x(idx)
end program
