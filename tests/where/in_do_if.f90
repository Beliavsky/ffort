program p
implicit none
integer::a(4)=[1,2,3,4],i
do i=1,3
if(i<3) then
where(a>i)
a=a+1
end where
end if
end do
print *,a
end program
