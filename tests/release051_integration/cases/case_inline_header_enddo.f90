implicit none
integer::i,n
i=1;n=0
select case(i)
case(1); do while(n<3)
n=n+1
enddo
case default
n=-1
end select
print '(i0)',n
end
