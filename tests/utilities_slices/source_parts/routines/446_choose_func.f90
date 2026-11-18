recursive function choose_func(n,k) result(cmb)
integer :: cmb
integer, intent(in) :: n,k
if (k > n .or. k < 0) then
   cmb = 0
   return
else if (n < 1 .or. k == 0) then
   cmb = 1
   return
end if
if (k == n) then
   cmb = 1
else if (k == 1) then
   cmb = n
else if (mm(n,k) /=0)  then
   cmb = mm(n,k)
else if ((k /= 1) .and. (k /= n)) then
   cmb = choose_func(n-1,k-1) + choose_func(n-1,k)
   mm(n,k) = cmb
end if      
end function choose_func
!
