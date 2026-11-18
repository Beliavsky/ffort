implicit none
integer::i,n
n=0
write(*,'(a)',advance='no')'SAFE'
outer: do while(.true.)
do i=1,2
n=n+1
cycle outer
end do
end do outer
end
