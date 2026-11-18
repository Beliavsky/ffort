implicit none
integer::i,j,n
i=0;n=0
outer: do while(i<3)
i=i+1
select case(i)
case(1)
do j=1,2
n=n+j
end do
case(2)
do while(n<13)
n=n+10
cycle outer
end do
case default
do
n=n+100
exit
end do
end select
end do outer
print '(i0,1x,i0)',i,n
end
