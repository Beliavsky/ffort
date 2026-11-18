! New wrapper only; five original bodies below retain exact source bytes.
module original_combinations
implicit none
integer,parameter::long_int=8
interface default
module procedure default_logical
end interface
contains
elemental function factorial_long(n) result(ifact)
integer(kind=long_int), intent(in) :: n
integer(kind=long_int)             :: ifact
integer(kind=long_int)             :: i
ifact = 1
do i=2,n
   ifact = ifact*i
end do
end function factorial_long
elemental function choose(n,k) result(j)
integer, intent(in)    :: n,k
integer                :: j
integer                :: i
integer(kind=long_int) :: numer,k_
if (k > n) then
   j = 0
   return
end if
if (n < 1) then
   j = 1
   return
end if
if (n == k .or. k == 0) then
   j = 1
   return
else if (k == 1 .or. k == n-1) then
   j = n
   return
end if
k_ = merge(n-k,k,k > n/2) 
numer = 1
do i=n-k_+1,n
   numer = numer*i
end do
j = numer/factorial_long(k_)
! print*,n,k,numer,factorial(k),j
end function choose
function few_combinations(n,k) result(imat)
integer, intent(in) :: n,k
integer             :: imat(choose(n,k),k)
integer             :: i1,i2,i3,ncomb
ncomb = 0
imat = 0
if (k == 3) then
   do i1=1,n
      do i2=i1+1,n
         do i3=i2+1,n
            ncomb = ncomb + 1
            imat(ncomb,:) = [i1,i2,i3]
         end do
      end do
   end do
end if
end function few_combinations
elemental function default_logical(def,opt) result(tf)
! return opt if it is present, otherwise def (logical arguments and result)
logical, intent(in)           :: def
logical, intent(in), optional :: opt
logical                       :: tf
if (present(opt)) then
   tf = opt
else
   tf = def
end if
end function default_logical
recursive subroutine gen(m,n_max,m_max,comb,comb_mat,zero_icomb)
! based on https://rosettacode.org/wiki/Combinations#Fortran
integer, intent(in)               :: m,n_max,m_max
integer, intent(in out)           :: comb(m_max)
integer, intent(in out)           :: comb_mat(:,:)
logical, intent(in)    , optional :: zero_icomb
integer                           :: n
integer, save                     :: icomb=0
logical                           :: call_gen
if (default(.false.,zero_icomb)) icomb = 0
if (m > m_max) then
   icomb = icomb + 1
   if (icomb <= size(comb_mat,1)) comb_mat(icomb,:) = comb
else
   do n = 1, n_max
      if (m == 1) then
         call_gen = .true.
      else if (n> comb(m - 1)) then
         call_gen = .true.
      else
         call_gen = .false.
      end if
      if (call_gen) then
         comb(m) = n
         call gen(m+1,n_max,m_max,comb,comb_mat)
      end if
   end do
end if
end subroutine gen
end module original_combinations
