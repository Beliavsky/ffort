implicit none
integer::i,n
n=0
outer: do i=1,3
n=n+1
end do outer
print "(i0)",n
end
