program demo
implicit none
integer::a(2,2,2)
a=1
where(a(:,:,pick())>0) a(:,:,1)=2
print *,a
contains
integer function pick()
pick=1
end function
end program
