program main
implicit none
integer::i,a(4),lo,hi,step
i=88
lo=7
hi=-2
step=-3
a=[(i,i=lo,hi,step)]
print *,a,i
end program
