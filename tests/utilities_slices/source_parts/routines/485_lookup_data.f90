function lookup_data(strings,string_data,ydata,msg_no_match) result(yy)
! return the values of ydata(:) corresponding to strings(:) in string_data(:)
character (len=*), intent(in) :: strings(:)
character (len=*), intent(in) :: string_data(:) ! (n)
real(kind=dp)    , intent(in) :: ydata(:)       ! (n)
character (len=*), intent(in), optional :: msg_no_match
real(kind=dp)                 :: yy(size(strings))
integer                       :: i,ipos,ndata
character (len=*), parameter  :: msg = "in util_mod::lookup_data, "
ndata = size(string_data)
if (size(ydata) /= ndata) then
   write (*,*) msg,"size(string_data), size(ydata)=",ndata,size(ydata)," must be equal, STOPPING"
   stop
end if
do i=1,size(strings)
   ipos = match_string(strings(i),string_data)
   if (ipos == 0) then
      write (*,*) msg
      if (present(msg_no_match)) then
         write (*,"(a)") trim(msg_no_match)
      else
         write (*,"('no match for')")
      end if
      write (*,*) trim(strings(i))
      stop "stopping"
   end if
   yy(i) = ydata(ipos)
end do
end function lookup_data
!
