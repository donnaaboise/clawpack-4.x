c     ============================================
      subroutine b4step2(maxmx,maxmy,mbc,mx,my,meqn,q,
     &            xlower,ylower,dx,dy,time,dt,maux,aux)
c     ============================================
c
c     # called before each call to step
c     # use to set time-dependent aux arrays or perform other tasks.
c
c     # dummy routine 
c
c     
      implicit double precision (a-h,o-z)
      dimension q(meqn,1-mbc:maxmx+mbc,1-mbc:maxmy+mbc)
c     dimension aux(maux,1-mbc:maxmx+mbc,1-mbc:maxmy+mbc)
c
       return
       end
