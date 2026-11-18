program control
implicit none
integer :: mode,i,n
do mode=1,4
 n=0
 if(mode==1) then
  first: do i=1,4
   if(i==2) cycle first
   if(i==4) exit first
   n=n+i
  end do first
  n=n+10
 else if(mode==2) then
  second: do i=1,4
   if(i==2) cycle second
   if(i==4) exit second
   n=n+i
  end do second
  n=n+10
 else
  select case(mode)
  case(3)
   third: do i=1,4
    if(i==2) cycle third
    if(i==4) exit third
    n=n+i
   end do third
   n=n+10
  case default
   fourth: do i=1,4
    if(i==2) cycle fourth
    if(i==4) exit fourth
    n=n+i
   end do fourth
   n=n+10
  end select
 end if
 print *,mode,n,i
end do
end program
